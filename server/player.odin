package main

import "core:fmt"
import "core:os"
import "core:encoding/json"

Player_status :: enum {
    Username,
    Password,
    Playing,
    Quitting,
}

Player :: struct {
    socket: i64,
    current_room: int,
    status: Player_status,
    name: string,
    max_hp: int,
    hp: int,
    damage: int,
    defense: int,
    attack_speed: int,
    experience: int,
    inventory: [10]int,
    equipment: [6]int,
}

players: map[i64]Player

players_create :: proc() -> Player {
    player := Player {
		name = "Tmp",
		current_room = 1,
		status = Player_status.Username,
		max_hp = 100,
		hp = 100,
		damage = 10,
        defense = 0,
        attack_speed = 1,
        experience = 0,
	}
    for i in 0..<10 {
        player.inventory[i] = -1
    }
    for i in 0..<6 {
        player.equipment[i] = -1
    }
    return player
}

players_save :: proc(player: ^Player) {
    if(!os.exists("saves")) {
        os.make_directory("saves")
    }
    path := fmt.aprintf("saves/%s", player.name)
    file, err := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
    if err != nil {
        fmt.println("Error opening file:", err)
        return
    }
    bepa: [1]Player
    bepa[0] = player^
    data, err2 := json.marshal(bepa)
    if err2 != nil {
        fmt.println("Error marshaling player:", err2)
        return
    }
    os.write(file, data)
    os.close(file)
    delete(path)
}

players_load :: proc(player: ^Player) -> bool {
    path := fmt.aprintf("/saves/%s", player.name)
    file, err := os.open(path, os.O_RDONLY)
    if err != nil {
        fmt.println("Error opening file:", err)
        return false
    }
    data, err2 := os.read_entire_file_from_file(file, context.allocator)
    if err2 != nil {
        fmt.println("Error reading file:", err2)
        return false
    }
    json_data: [1]Player
    error := json.unmarshal(data, &json_data)
    if error != nil {
        fmt.println("Error unmarshaling player:", error)
        return false
    }
    player^ = json_data[0]
    delete(path)
    delete(data, context.allocator)
    return true
}

players_inv_add :: proc(player: ^Player, item_index: int) -> bool {
    for i in 0..<10 {
        if player.inventory[i] == -1 {
            player.inventory[i] = item_index
            return true
        }
    }
    return false
}

players_equip_get :: proc(player: ^Player, slot: int) -> string {
    if slot < 0 || slot >= 6 {
        return "None"
    }
    if player.equipment[slot] != -1 {
        return Items[player.equipment[slot]].name
    } else {
        return "None"
    }
}

players_get_damage :: proc(player: ^Player) -> int {
    damage := player.damage
    item_index := player.equipment[0]
    if item_index != -1 {
        damage += Items[item_index].stat
    }
    return damage
}

players_get_defense :: proc(player: ^Player) -> int {
    defense := player.defense
    for i in 1..<6 {
        item_index := player.equipment[i]
        if item_index != -1 {
            defense += Items[item_index].stat
        }
    }
    return defense
}

players_leave :: proc(player: ^Player, sock: i64) {
    players_save(player)
    rooms_send(player, fmt.aprintf("%s has left the game.", player.name))
    delete(players[sock].name)
    delete_key(&rooms[player.current_room].players, player.name)
    delete_key(&players, sock)
}