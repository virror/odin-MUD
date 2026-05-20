package main

import "core:fmt"
import "core:net"
import "core:strings"

m: map[string]proc(string, ^Player) -> string

input_init :: proc() {
    m = make(map[string]proc(string, ^Player) -> string)
    m["quit"] = input_quit
	m["look"] = input_look
	m["north"] = input_north
    m["south"] = input_south
    m["east"] = input_east
    m["west"] = input_west
    m["say"] = input_say
    m["char"] = input_char
    m["take"] = input_take
    m["attack"] = input_attack
    m["examine"] = input_examine
    m["inventory"] = input_inventory
    m["equip"] = input_equip
}

input_handle :: proc(sock: net.TCP_Socket, data: []u8) {
    fmt.printfln("Received string: %s", string(data))
    command := strings.split(string(data), " ")[0]
    elem, ok := m[command]
    if(!ok) {
        send_msg(sock, "Invalid command")
        return
    }
    msg := elem(string(data), &players[i64(sock)])
    send_msg(sock, msg)
    delete(msg)
}

input_quit :: proc(data: string, player: ^Player) -> string {
    player.status = Player_status.Quitting
    return strings.clone("Do you want to quit? (yes/no)")
}

input_look :: proc(data: string, player: ^Player) -> string {
	return rooms_description(player.current_room, player)
}

input_north :: proc(data: string, player: ^Player) -> string {
	return rooms_move(player, 0)
}

input_south :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 2)
}

input_east :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 1)
}

input_west :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 3)
}

input_say :: proc(data: string, player: ^Player) -> string {
    msg, ok := strings.substring(data, 4, len(data))
    if !ok {
        return strings.clone("Usage: say <message>")
    }
    message := fmt.aprintf("%s says: %s", player.name, msg)
    rooms_send(player, message)
    return fmt.aprintf("You say: %s", msg)
}

input_char :: proc(data: string, player: ^Player) -> string {
    return fmt.aprintf("+------------------+\n| Name: %s\n| HP: %d/%d\n| Damage: %d\n| Defense: %d\n| Attack Speed: %d\n| Experience: %d/1000\n+------------------+\n| Main hand: %s\n| Off hand: %s\n| Head: %s\n| Body: %s\n| Legs: %s\n| Feet: %s\n+------------------+",
        player.name, player.hp, player.max_hp, player_get_damage(player), player_get_defense(player), player.attack_speed, player.experience,
        player_equip_get(player, 0),
        player_equip_get(player, 1),
        player_equip_get(player, 2),
        player_equip_get(player, 3),
        player_equip_get(player, 4),
        player_equip_get(player, 5))
}

input_take :: proc(data: string, player: ^Player) -> string {
    entity_name, ok := strings.substring(data, 5, len(data))
    if !ok {
        return strings.clone("Usage: take <item>")
    }
    current_room := rooms[player.current_room]
    entity, exists := current_room.entities[entity_name]

    if !exists {
        return fmt.aprintf("There is no %s here.", entity_name)
    }
    item, val_ok := entity.(Item)
    if !val_ok {
        return fmt.aprintf("You can't take the %s.", entity_name)
    }

    if !player_inv_add(player, item.index) {
        current_room.entities[entity_name] = item
        return strings.clone("Your inventory is full.")
    }
    delete_key(&current_room.entities, entity_name)
    return fmt.aprintf("You take the %s.", Items[item.index].name)
}

input_attack :: proc(data: string, player: ^Player) -> string {
    entity_name, ok := strings.substring(data, 7, len(data))
    if !ok {
        return strings.clone("Usage: attack <enemy>")
    }
    current_room := rooms[player.current_room]
    entity, exists := current_room.entities[entity_name]
    if !exists {
        return fmt.aprintf("There is no %s here.", entity_name)
    }
    enemy, val_ok := entity.(Enemy)
    if !val_ok {
        return fmt.aprintf("You can't attack the %s.", entity_name)
    }
    if enemy.hp <= 0 {
        return fmt.aprintf("The %s is already dead.", entity_name)
    }
    return fmt.aprintf("You attack the %s. It has %d HP left.", entity_name, enemy.hp)
}

input_examine :: proc(data: string, player: ^Player) -> string {
    entity_name, ok := strings.substring(data, 8, len(data))
    if !ok {
        return strings.clone("Usage: examine <entity>")
    }
    current_room := rooms[player.current_room]
    entity, exists := current_room.entities[entity_name]
    if !exists {
        return fmt.aprintf("There is no %s here.", entity_name)
    }
    switch v in entity {
    case Item:
        item := entity.(Item)
        return fmt.aprintf("%s", Items[item.index].description)
    case Enemy:
        enemy := entity.(Enemy)
        return fmt.aprintf("%s", enemy.description)
    case:
        return strings.clone("You can't examine that.")
    }
}

input_inventory :: proc(data: string, player: ^Player) -> string {
    length := len("Your inventory:")
    for i in 0..<10 {
        if player.inventory[i] != -1 {
            item_index := player.inventory[i]
            length += len(Items[item_index].name) + 3
        }
    }
    builder := strings.builder_make_len_cap(0, length)
    strings.write_string(&builder, "Your inventory:")
    for i in 0..<10 {
        if player.inventory[i] != -1 {
            item_index := player.inventory[i]
            fmt.sbprintf(&builder, "\n- %s", Items[item_index].name)
        }
    }
    final_string := strings.clone(strings.to_string(builder))
    strings.builder_destroy(&builder)
    return final_string
}

input_equip :: proc(data: string, player: ^Player) -> string {
    item_name, ok := strings.substring(data, 6, len(data))
    if !ok {
        return strings.clone("Usage: equip <item>")
    }
    item_index := -1
    for i in 0..<10 {
        if player.inventory[i] != -1 {
            if Items[player.inventory[i]].name == item_name {
                item_index = player.inventory[i]
                break
            }
        }
    }
    if item_index == -1 {
        return fmt.aprintf("You don't have a %s in your inventory.", item_name)
    }
    item_type := Items[item_index].type
    equip_slot := -1
    tmp_idx := -1
    #partial switch item_type {
    case Item_type.Weapon:
        equip_slot = 0
    case Item_type.Shield:
        equip_slot = 1
    case Item_type.Armor:
        equip_slot = 2
    case Item_type.Helmet:
        equip_slot = 3
    case Item_type.Pants:
        equip_slot = 4
    case Item_type.Boots:
        equip_slot = 5
    case:
        return fmt.aprintf("You can't equip a %s.", Items[item_index].name)
    }
    if player.equipment[equip_slot] != -1 {
        tmp_idx = player.equipment[equip_slot]
    }
    player.equipment[equip_slot] = item_index
    for i in 0..<10 {
        if player.inventory[i] == item_index {
            player.inventory[i] = -1
            break
        }
    }
    if tmp_idx != -1 {
        player_inv_add(player, tmp_idx)
    }
    return fmt.aprintf("You equip the %s.", Items[item_index].name)
}