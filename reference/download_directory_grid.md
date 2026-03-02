# Download a DevExpress grid as CSV from the ALSDE Education Directory

The Education Directory page uses DevExpress ASPxGridView controls.
Export is triggered by posting back to the same page with the grid's
UniqueID as \_\_EVENTTARGET and serialized DevExpress callback args as
\_\_EVENTARGUMENT.

## Usage

``` r
download_directory_grid(grid_unique_id, description)
```

## Arguments

- grid_unique_id:

  The ASP.NET UniqueID of the grid control (e.g.,
  "pcResults\$gridPublicSchool")

- description:

  Human-readable description for logging

## Value

Data frame with directory data

## Details

The serialized format for ExportTo("Csv") is: "6\|EXPORT3\|Csv" This
comes from the DevExpress SerializeCallbackArgs function which encodes
each argument as: length\|value
