resource "aws_s3_bucket" "bucket-name" {
  bucket = "${var.env}-${var.bucket}"

  tags = {
    Name        = "${var.env}-bucket-for-learning"
    Environment = var.env
  }
}