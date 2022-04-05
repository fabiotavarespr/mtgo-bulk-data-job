-- name: CreateBulk :one
INSERT INTO bulk (
    updated_at,
    download_uri,
    status
) VALUES (
    $1, $2, $3
) RETURNING *;

-- name: GetBulk :one
SELECT * FROM bulk
WHERE updated_at = $1 LIMIT 1;

-- name: UpdateBulk :one
UPDATE bulk
SET status = $2
WHERE id = $1
RETURNING *;
