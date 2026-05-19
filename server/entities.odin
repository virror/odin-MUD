package main

import "core:fmt"

Entity :: union {
    Item,
    Enemy,
}

Item :: struct {
    index: int,
}

Enemy :: struct {
    name: string,
    description: string,
    hp: int,
    damage: int,
    attack_speed: int,
}

Item_data :: struct {
    name: string,
    description: string,
}

Items: []Item_data = {
    {name = "stick", description = "A simple stick. It looks like it could be used as a weapon."},
}