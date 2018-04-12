variable name {}

resource "aws_ecr_repository" "this" {
  name = "${var.name}"
}

/* resource "aws_ecr_repository_policy" "this" { */
/*   repository = "${aws_ecr_repository.this.name}" */

/*   policy = <<EOF */
/* EOF */
/* } */

output "arn" {
  value = "${aws_ecr_repository.this.arn}"
}
output "name" {
  value = "${aws_ecr_repository.this.name}"
}
output "url" {
  value = "${aws_ecr_repository.this.repository_url}"
}
