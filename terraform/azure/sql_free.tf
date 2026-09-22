resource "azurerm_mssql_server" "sql_server" {
  name                         = "nikhilsrh07-sql-srv"
  resource_group_name          = "nikhilsrh07-rg"
  location                     = "East US"
  version                      = "12.0"
  administrator_login          = "nikhilsrh07"
  administrator_login_password = var.administrator_login_password
}

resource "azurerm_mssql_database" "free_db" {
  name                        = "nikhildb"
  server_id                   = azurerm_mssql_server.sql_server.id
  max_size_gb                 = 2
  sku_name                    = "GP_S_Gen5_1" # Serverless Compute
  auto_pause_delay_in_minutes = 60            # Auto-shutoff when inactive ($0 Fees)
}
