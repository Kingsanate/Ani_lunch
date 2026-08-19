package storage

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// R2Client wraps a Cloudflare R2 (S3-compatible) bucket for media storage.
// Images and videos NEVER pass through the Go API; clients upload directly
// using short-lived presigned URLs generated here.
type R2Client struct {
	client     *s3.Client
	bucket     string
	publicBase string // e.g. https://cdn.animeat.app
}

// Config holds R2 connection settings loaded from environment.
type Config struct {
	AccountID       string
	AccessKeyID     string
	SecretAccessKey string
	Bucket          string
	PublicBase      string
}

// NewR2Client constructs an S3 client pointed at Cloudflare R2.
// R2's endpoint is https://<accountId>.r2.cloudflarestorage.com
func NewR2Client(ctx context.Context, cfg Config) (*R2Client, error) {
	if cfg.AccountID == "" || cfg.AccessKeyID == "" || cfg.SecretAccessKey == "" {
		return nil, fmt.Errorf("incomplete R2 configuration")
	}
	endpoint := fmt.Sprintf("https://%s.r2.cloudflarestorage.com", cfg.AccountID)

	awsCfg, err := awsconfig.LoadDefaultConfig(ctx,
		awsconfig.WithRegion("auto"),
		awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})

	return &R2Client{
		client:     client,
		bucket:     cfg.Bucket,
		publicBase: cfg.PublicBase,
	}, nil
}

// PresignUpload generates a short-lived PUT presigned URL for a client to
// upload an object directly to R2. TTL defaults to 5 minutes.
func (r *R2Client) PresignUpload(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	if ttl <= 0 {
		ttl = 5 * time.Minute
	}
	presigner := s3.NewPresignClient(r.client)
	req, err := presigner.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(r.bucket),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
	}, s3.WithPresignExpires(ttl))
	if err != nil {
		return "", fmt.Errorf("failed to presign upload: %w", err)
	}
	return req.URL, nil
}

// PresignDownload generates a short-lived GET presigned URL for a private object.
func (r *R2Client) PresignDownload(ctx context.Context, key string, ttl time.Duration) (string, error) {
	if ttl <= 0 {
		ttl = 15 * time.Minute
	}
	presigner := s3.NewPresignClient(r.client)
	req, err := presigner.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(ttl))
	if err != nil {
		return "", fmt.Errorf("failed to presign download: %w", err)
	}
	return req.URL, nil
}

// PublicURL returns the CDN URL for an object if a public base is configured.
func (r *R2Client) PublicURL(key string) string {
	if r.publicBase == "" {
		return ""
	}
	return fmt.Sprintf("%s/%s", r.publicBase, key)
}

// Delete removes an object (used by admin/content cleanup).
func (r *R2Client) Delete(ctx context.Context, key string) error {
	_, err := r.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	return err
}
