extends Node


var player_instance = null
var nav_region = null
var camera_instance = null
var terrain_generation = null

var robot_index = 0
var taxes: Array[String] = [
"Federal Income Tax",
"Provincial Income Tax",
"Federal Sales Tax",
"Provincial Sales Tax",
"Property Tax",
"Custom Duties",
"Tarrifs",
"Health Insurance Tax",
"Capital Gains Tax",
"Carbon Tax"
]
