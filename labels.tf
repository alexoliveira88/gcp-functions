module "bvs-labels" {
  source = "gcs::https://www.googleapis.com/storage/v1/bvs-terraform-modules/bvs-labels-v1.0.4.zip"
  ## Labels padronizadas que deverão ser passadas pelo módulo do recurso como map
  labels = var.labels
  ## Labels que podem ser definidas pelo usuário do módulo (chave-valor)
  extra_labels = var.extra_labels
}

variable "labels" {
  description = "Labels que são necessárias para criaçao e identificação de um recurso"
  type = object({
    product      = string
    application  = string
    value-stream = string
    squad        = string
  })

}

variable "extra_labels" {
  description = "Labels extras que queira adicionar aos recursos. \nExemplo: `{ expiracao = \"out-2020\" }`\n São do tipo chave-valor"
  type        = map(string)
  default     = {}
}
