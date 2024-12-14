resource "google_monitoring_dashboard" "image_processing_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Image Processing Dashboard"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "Upload Sizes"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"custom.googleapis.com/image_processing/upload_size_bytes\" resource.type=\"cloud_run_revision\""
                  aggregation = {
                    alignmentPeriod   = "60s"
                    perSeriesAligner  = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
              legendTemplate = "Upload Size (bytes)"
            }]
            yAxis = {
              label = "Bytes"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Successful Uploads"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"custom.googleapis.com/image_processing/successful_uploads\" resource.type=\"cloud_run_revision\""
                  aggregation = {
                    alignmentPeriod   = "60s"
                    perSeriesAligner  = "ALIGN_RATE"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
              legendTemplate = "Successful Uploads"
            }]
            yAxis = {
              label = "Count/minute"
              scale = "LINEAR"
            }
          }
        }
      ]
    }
  })
}