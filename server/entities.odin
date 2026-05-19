package main

import "core:fmt"

Item_type :: enum {
    Weapon,
    Shield,
    Helmet,
    Armor,
    Pants,
    Boots,
    Consumable,
}

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
    type: Item_type,
    stat: int,
}

Items: []Item_data = {
    {
        name = "Stick",
        description = "A simple stick. It looks like it could be used as a weapon.",
        type = Item_type.Weapon,
        stat = 2,
    },
}