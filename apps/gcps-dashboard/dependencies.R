# dependencies.R -- not sourced by the app. It exists so renv's static
# dependency discovery (and a human reader) can see every package the app needs.
# The authoritative install list is in setup.R; the authoritative lock is
# renv.lock.

library(shiny)        # app framework
library(bslib)        # GCPS UI shells (gcps_bs_theme)
library(leaflet)      # interactive map
library(sf)           # spatial data (bundled nc.shp)
library(ggplot2)      # static map
library(htmltools)    # inject GCPS interactive CSS
library(htmlwidgets)  # prependContent
library(scales)       # label_comma
library(rcds)         # the design system (GitHub: rrichard-gcps/Geocomputation, subdir=rcds)
