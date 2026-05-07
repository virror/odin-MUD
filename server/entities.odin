package main

import "core:fmt"

Entity :: union {
    Item,
    Enemy,
}

Item :: struct {
    name: string,
    description: string,
}

Enemy :: struct {
    name: string,
    description: string,
    hp: int,
    damage: int,
    attack_speed: int,
}