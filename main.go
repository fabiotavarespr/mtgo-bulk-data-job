package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"io/ioutil"
	"log"
	"net/http"

	env "github.com/fabiotavarespr/go-env"
	logger "github.com/fabiotavarespr/go-logger"
	"github.com/fabiotavarespr/go-logger/attributes"
	"github.com/fabiotavarespr/mtgo-bulk-data-job/platform/database/sqlc"

	_ "github.com/lib/pq"
)

var testQueries *sqlc.Queries
var testDB *sql.DB

const (
	dbDriver = "postgres"
	dbSource = "postgres://root:mtgo-bulk-data@localhost:5432/mtgo-bulk-data?sslmode=disable"
)

type BulkData struct {
	Object  string  `json:"object"`
	HasMore bool    `json:"has_more"`
	Bulk    []*Bulk `json:"data"`
}

type Bulk struct {
	Object          string `json:"object"`
	Id              string `json:"id"`
	Type            string `json:"type"`
	UpdatedAt       string `json:"updated_at"`
	Uri             string `json:"uri"`
	Name            string `json:"name"`
	Description     string `json:"description"`
	CompressedSize  int64  `json:"compressed_size"`
	DownloadUri     string `json:"download_uri"`
	ContentType     string `json:"content_type"`
	ContentEncoding string `json:"content_encoding"`
}

func main() {

	logger.Init(&logger.Option{
		ServiceName:    env.GetEnvWithDefaultAsString("SERVICE", "Testing"),
		ServiceVersion: env.GetEnvWithDefaultAsString("VERSION", "0.0.1"),
		Environment:    env.GetEnvWithDefaultAsString("ENVIRONMENT", "dev"),
		LogLevel:       env.GetEnvWithDefaultAsString("LOG_LEVEL", "debug"),
	})

	defer logger.Sync()
	var err error
	testDB, err = sql.Open(dbDriver, dbSource)
	if err != nil {
		details := attributes.New().WithError(errors.New("interrupt signal detected"))
		details["dbDriver"] = dbDriver
		details["dbSource"] = dbSource

		logger.Fatal("Connection fail", details)
	}

	testQueries = sqlc.New(testDB)

	resp, err := http.Get("https://api.scryfall.com/bulk-data")
	if err != nil {
		logger.Fatal("Connection fail", attributes.New().WithError(err))
	}
	//We Read the response body on the line below.
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		logger.Fatal("ReadAll fail", attributes.New().WithError(err))
	}
	//Convert the body to type string
	var bulkData BulkData
	err = json.Unmarshal(body, &bulkData)
	if err != nil {
		log.Println(err)
	}

	for _, bulk := range bulkData.Bulk {
		if bulk.Name == "All Cards" {
			uBulk, err := testQueries.GetBulk(context.Background(), bulk.UpdatedAt)
			if err != nil {
				if uBulk.ID == 0 {
					arg := sqlc.CreateBulkParams{
						UpdatedAt:   bulk.UpdatedAt,
						DownloadUri: bulk.DownloadUri,
						Status:      "INIT",
					}

					newBulk, err := testQueries.CreateBulk(context.Background(), arg)
					if err != nil {
						logger.Fatal("CreateBulk fail", attributes.New().WithError(err))
					}

					logger.Info("Created bulk", attributes.New().WithField("newBulk", newBulk))
				}
			} else {
				logger.Info("Existed bulk", attributes.New().WithField("uBulk", uBulk))
			}
		}
	}
}
