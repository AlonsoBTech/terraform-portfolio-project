terraform {
    backend "s3" {
        bucket = "aeb-blog-terraform-state"
        key = "global/s3/terraform.state"
        region = "ca-central-1"
        dynamodb_table "terraform-lock-file"
    }
}