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
        return "Usage: say <message>"
    }
    message := fmt.aprintf("%s says: %s", player.name, msg)
    rooms_send(player, message)
    return fmt.aprintf("You say: %s", msg)
}

input_char :: proc(data: string, player: ^Player) -> string {
    return fmt.aprintf("+------------------+\n| Name: %s\n| HP: %d/%d\n| Damage: %d\n| Attack Speed: %d\n| Experience: %d/1000\n+------------------+",
        player.name, player.hp, player.max_hp, player.damage, player.attack_speed, player.experience)
}

input_take :: proc(data: string, player: ^Player) -> string {
    entity_name, ok := strings.substring(data, 5, len(data))
    if !ok {
        return "Usage: take <item>"
    }
    current_room := rooms[player.current_room]
    entity, exists := current_room.entities[entity_name]
    fmt.println(current_room)
    if !exists {
        return fmt.aprintf("There is no %s here.", entity_name)
    }
    item, val_ok := entity.(Item)
    if !val_ok {
        return fmt.aprintf("You can't take the %s.", entity_name)
    }

    delete_key(&current_room.entities, entity_name)
    return fmt.aprintf("You take the %s.", item.name)
}

input_attack :: proc(data: string, player: ^Player) -> string {
    entity_name, ok := strings.substring(data, 7, len(data))
    if !ok {
        return "Usage: attack <enemy>"
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