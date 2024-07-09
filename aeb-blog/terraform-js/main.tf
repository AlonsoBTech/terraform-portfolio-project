terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

# S3 Bucket
resource "aws_s3_bucket" "nextjs_bucket" {
  bucket = "aeb-blog-nextjs-bucket"

  tags = {
    Name        = "AEB-Blog Next.js Bucket"
    Environment = "Dev"
  }
}

# S3 Bucket Ownership
resource "aws_s3_bucket_ownership_controls" "nextjs_bucket_ownership" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "nextjs_public_access_block" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket ACLs
resource "aws_s3_bucket_acl" "nextjs_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.nextjs_bucket_ownership,
    aws_s3_bucket_public_access_block.nextjs_public_access_block
  ]

  bucket = aws_s3_bucket.nextjs_bucket.id
  acl    = "public-read"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "nextjs_website_config" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.nextjs_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "cdn_origin_access_identity" {
  comment = "Origin Access Identity for Next.js portfolio website"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "nextjs_cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.nextjs_bucket.bucket_regional_domain_name
    origin_id   = "s3-nextjs-portfolio-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AEB-Blog Next.js portfolio site"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-nextjs-portfolio-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}