local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Modules = ReplicatedStorage:WaitForChild('Modules')
local logger = require(Modules.src.utils.Logger)

local Dict = require(Modules.src.utils.Dict)
local None = require(Modules.src.utils.None)
local Print = require(Modules.src.utils.Print)
local InventoryObjects = require(Modules.src.objects.InventoryObjects)
local RoomObjects = InventoryObjects.RoomObjects
local GlobalConfig = require(Modules.src.GlobalConfig)
local M = require(Modules.M)


local roomInitial={
 
    playersWaiting = {},
    playersPlaying = {
        --[[  Player1 = {
            id = "1",
            finishTime = 1577984576.7429,
            name = "trimatech1"
        },
        Player2 = {
            id = "2",
            finishTime = 1577994576.7429,
            name = "trimatech2"
        },
        Player3 = {
            id = "3",
            finishTime = 1577988576.7429,
            name = "trimatech3"
        }]] --
    },
    endTime =  nil,
    --  startTime = 1577984537.9199,
    countDownTime = nil,
    countDownText = nil
}

function initRoom (roomObject)
    return M.extend({}, roomInitial, roomObject)
end

local function rooms(state, action)
    state = state or M.map(RoomObjects, initRoom)

    if action.type == "playerDied" then

        logger:d("Player died. Removing from rooms. Marking as DNF")

        local roomId

        function FindPlayerFromRoom(room, rId)
            local playersPlaying = state[rId].playersPlaying
            local existingPlayer = playersPlaying[action.playerId]
    
            if existingPlayer and not existingPlayer.finishTime then
                roomId = rId
            end
        end

         M.each(state, FindPlayerFromRoom)

        if roomId then
            local playersPlaying = state[roomId].playersPlaying
            logger:d("Player " .. action.playerId .. " DNF" )

            local newPlayers = Dict.join(playersPlaying, {
                [action.playerId] = {
                    id = action.playerId,
                    name = action.playerName,
                    finishTime = os.time(),
                    isKilled = true,
                }
            })

            local newRoom = Dict.join(state[roomId], {playersPlaying = newPlayers})
    
            return Dict.join(state, {[roomId] = newRoom})
        end
        return state
    elseif  action.type == "addPlayerToRoom" then
        local roomId = action.roomId
        local playersWaiting = state[roomId].playersWaiting
        local existingPlayer = playersWaiting[action.playerId]

        if existingPlayer ~= nil then
            logger:w("Player already added " .. action.playerId)
            return state
        end
        
        logger:d("Adding player"..tostring(action.playerId).." to room:"..roomId )
        local newPlayers = Dict.join(playersWaiting, {
            [action.playerId] = {id = action.playerId, name = action.playerName}
        })
        local newRoom = Dict.join(state[roomId], {playersWaiting = newPlayers})

        return Dict.join(state, {[roomId] = newRoom})
    elseif action.type == "addPlayerFinishToRoom" then
        local roomId = action.roomId
        local playersPlaying = state[roomId].playersPlaying
        local existingPlayer = playersPlaying[action.playerId]

        if existingPlayer == nil then
            logger:w("No player to edit " .. action.playerId)
            return state
        end
        logger:d("Adding player " .. action.playerId .. " finish time " ..
                 action.finishTime)
        local newPlayers = Dict.join(playersPlaying, {
            [action.playerId] = {
                id = action.playerId,
                name = action.playerName,
                finishTime = action.finishTime,
                coins = action.coins,

            }
        })
        local newRoom = Dict.join(state[roomId], {playersPlaying = newPlayers})

        return Dict.join(state, {[roomId] = newRoom})

    elseif action.type == "removePlayerFromRoom" then
        local roomId = action.roomId
        local playersWaiting = state[roomId].playersWaiting

        local existingPlayer = playersWaiting[action.playerId]

        if existingPlayer == nil then
            logger:w("No player to remove " .. action.playerId)
            return state
        end

        local newPlayers = Dict.join(playersWaiting, {[action.playerId] = None})
        local newRoom = Dict.join(state[roomId], {playersWaiting = newPlayers})

        return Dict.join(state, {[roomId] = newRoom})
    elseif action.type == "setRoomCountDown" then
        local roomId = action.roomId

        local newRoom = Dict.join(state[roomId], {
            countDownTime = action.countDownTime and action.countDownTime or None,
            countDownText = action.text,
            countDownTextOther = action.textOther and action.textOther or None,
        })

        return Dict.join(state, {[roomId] = newRoom})
    elseif action.type == "setRoomStartTime" then
        local roomId = action.roomId
        local playersStarting = action.playersStarting

        local newRoom = Dict.join(state[roomId], {
            startTime = action.startTime,
            endTime = None,
            playersPlaying = playersStarting
        })

        return Dict.join(state, {[roomId] = newRoom})

    elseif action.type == "setRoomEndTime" then
        local roomId = action.roomId
        local newRoom = Dict.join(state[roomId], {
            endTime = action.startTime and action.startTime or None,
        })

        return Dict.join(state, {[roomId] = newRoom})
    elseif action.type == "resetRoom" then
        local roomId = action.roomId
        local newRoom = Dict.join(state[roomId], {
            endTime = None,
            startTime = None,
            playersPlaying={}
        })

        return Dict.join(state, {[roomId] = newRoom})
    end

    return state
end

return rooms
