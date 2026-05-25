resource "yandex_iam_service_account" "function" {
  name        = var.sa_name
  description = "Cloud Function for Minecraft status API"
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

resource "yandex_function" "status" {
  name               = var.function_name
  description        = "Minecraft server status JSON API"
  user_hash          = data.archive_file.function_zip.output_md5
  runtime            = "python312"
  entrypoint         = "index.handler"
  memory             = 128
  execution_timeout  = 10
  service_account_id = yandex_iam_service_account.function.id

  content {
    zip_filename = data.archive_file.function_zip.output_path
  }

  environment = {
    MINECRAFT_HOST = var.minecraft_host
    MINECRAFT_PORT = var.minecraft_port
  }
}

resource "yandex_function_iam_binding" "gateway" {
  function_id = yandex_function.status.id
  role        = "serverless.functions.invoker"
  members     = ["serviceAccount:${yandex_iam_service_account.function.id}"]
}

resource "yandex_function_iam_binding" "public" {
  function_id = yandex_function.status.id
  role        = "serverless.functions.invoker"
  members     = ["system:allUsers"]
}
