# Go

## The client

```go
package storage

import (
	"context"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// From `graphon workspaces get`. It is not a secret.
const workspaceID = "<workspace id>"

// One bucket per environment. It is not a secret.
var bucket = os.Getenv("GRAPHON_BUCKET")

func New(ctx context.Context) *s3.Client {
	key := os.Getenv("GRAPHON_API_KEY")
	// The access key ID is between the "_" and the ".".
	id := key[strings.Index(key, "_")+1 : strings.Index(key, ".")]
	return s3.New(s3.Options{
		BaseEndpoint: aws.String("https://" + workspaceID + ".storage.beta.graphon.sh"),
		Region:       "us-east-1",
		UsePathStyle: true,
		Credentials:  credentials.NewStaticCredentialsProvider(id, key, ""),
	})
}
```

## Sign an upload URL

```go
func UploadURL(ctx context.Context, client *s3.Client, key, contentType string) (string, error) {
	presign := s3.NewPresignClient(client, s3.WithPresignExpires(10*time.Minute))
	out, err := presign.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", err
	}
	return out.URL, nil
}
```

Build the key from the authenticated user and a new UUID, never from the
uploaded filename.
