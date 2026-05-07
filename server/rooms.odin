package main

import "core:fmt"
import "core:strings"

Room :: struct {
    description: string,
    players: map[string]^Player,
    entities: map[string]Entity,
    north: int,
    south: int,
    east: int,
    west: int,
}

rooms: [4]Room

rooms_init :: proc() {
    rooms[0] = Room {
        description = "Dummy room.",
    }

    rooms[1] = Room {
        description = "You are in a big hall. There are exits to the north and south.\nThere is a stick on the ground.",
        north = 2,
        south = 3,
    }
    stick: Entity = Item {
        name = "Stick",
        description = "A simple stick. It looks like it could be used as a weapon.",
    }
    rooms[1].entities["stick"] = stick

    rooms[2] = Room {
        description = "You are in a small room. There is an exit to the south.",
        south = 1,
    }
    
    rooms[3] = Room {
        description = "You are in a dark cave. There is an exit to the north.\nThere is a goblin here!",
        north = 1,
    }
    goblin: Entity = Enemy {
        name = "Goblin",
        description = "A small, green goblin. It looks hostile.",
        hp = 30,
        damage = 5,
        attack_speed = 2,
    }
    rooms[3].entities["goblin"] = goblin
}

rooms_send :: proc(player: ^Player, message: string) {
    for _, p in rooms[player.current_room].players {
        if p.socket != player.socket {
            send_msg2(p.socket, message)
        }
    }
    delete(message)
}

rooms_move :: proc(player: ^Player, direction: int) -> string {
    current_room := rooms[player.current_room]
    delete_key(&current_room.players, player.name)
    message := fmt.aprintf("%s leaves the room", player.name)
    rooms_send(player, message)
    next_room_index: int
    switch direction {
    case 0:
        next_room_index = current_room.north
    case 2:
        next_room_index = current_room.south
    case 1:
        next_room_index = current_room.east
    case 3:
        next_room_index = current_room.west
    }
    if next_room_index == 0 {
        return "You can't go that way."
    }
    player.current_room = next_room_index
    rooms[next_room_index].players[player.name] = player
    message = fmt.aprintf("%s enters the room", player.name)
    rooms_send(player, message)
    return strings.clone(rooms[next_room_index].description)
}