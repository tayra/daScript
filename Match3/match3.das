require daslib/media
require random
require dasbox
require graphics
require math

options debugger
require daslib/debug

let
    FONT_WIDTH = 4
    FONT_HEIGHT = 5
    font = [[string[FONT_HEIGHT]
        "###  #  ### ### # # ### ### ### ### ### ";
        "# # ##    #   # # # #   #     # # # # # ";
        "# #  #  ###  ## ### ### ###  #  ### ### ";
        "# #  #  #     #   #   # # # #   # #   # ";
        "### ### ### ###   # ### ### #   ### ### "
    ]]

    IMG_SIZE = float(135)
    COL_NUM = ceil(float(get_screen_width() / int(IMG_SIZE)))
    ROW_NUM = ceil(float(get_screen_height() / int(IMG_SIZE)))
    COLORS = [[uint[5]0x00FF00; 0xFF0000; 0xF090F0; 0x229090; 0xFFFF00]]
    PATH_BASE = "piece.png"

struct Piece
    uid: int2    
    pType: int
    position: float2
    color: uint
    selected: bool

var    
    seed: int4
    score: int
    LBTPressed = false
    pieces: array<Piece>
    selected: array<Piece>

def initPice(var p: Piece; row: int; col: int)    
    p.uid = int2(row, col)
    p.pType = random_int(seed)%5
    p.color = COLORS[p.pType]
    p.position = float2(float(row)*IMG_SIZE, float(col)*IMG_SIZE)

def initField()
    for i in range(COL_NUM)
        for j in range(ROW_NUM)
            var p: Piece
            initPice(p, i, j)
            push(pieces, p)

def updateInput()
    if get_mouse_button_down(MB_LEFT)
        LBTPressed = true        
    if get_mouse_button_up(MB_LEFT)
        LBTPressed = false
    if LBTPressed
        checkPieceUnderMouse(get_mouse_position())
    else
        removeChain()
    
def renderPiece(var p: Piece)
    var color = 0xFFFFFF
    var size = IMG_SIZE    
    var delta = 0.0
    var imgPath = "{p.pType}{PATH_BASE}"
    var img: Image
    img <- create_image(imgPath)    
    premultiply_alpha(img)
    set_image_smooth(img, true)
    if p.selected
        color = p.color
        size = IMG_SIZE*1.1
        delta = IMG_SIZE*0.05
    draw_image(img, float(p.uid.x) * IMG_SIZE - delta, float(p.uid.y) * IMG_SIZE - delta, color, size)

def renderField()
    for p in pieces
        renderPiece(p)

def isValid(var p: Piece)
    if length(selected) > 0 && selected[0].pType != p.pType
        return false
    let index = find_index_if(selected) <| $(inst)
        return inst.uid == p.uid
    if length(selected) > 0
        var last = selected[length(selected) - 1]
        if !((p.uid.x == last.uid.x && (p.uid.y == last.uid.y - 1 || p.uid.y == last.uid.y + 1))
            || ((p.uid.x == last.uid.x + 1 || p.uid.x == last.uid.x - 1) && (p.uid.y == last.uid.y || p.uid.y == last.uid.y - 1 || p.uid.y == last.uid.y + 1)))
            return false
    return index < 0
    
def checkPieceUnderMouse(var mPos: float2)
    for p in pieces
        if (isValid(p) && mPos.x > p.position.x && mPos.x < p.position.x + IMG_SIZE &&
            mPos.y > p.position.y && mPos.y < p.position.y + IMG_SIZE)
            p.selected = true
            push(selected, p)

def removeChain()
    for s in selected
        for p in pieces
            if s.uid == p.uid
                p.selected = false
                if length(selected) >= 3
                    p.pType = random_int(seed)%5
                    p.color = COLORS[p.pType]
                    score++
    clear(selected)

def render_num_centered(x: int; y: int; size: int; border: int; num: int; color: uint)
    let buf = "{num}"
    let len = length(buf)
    let left = x - FONT_WIDTH * size * len / 2
    var i = -1

    for c in buf
        i++
        let n = c - '0'
        for iy in range(0, FONT_HEIGHT)
            for ix in range(0, FONT_WIDTH)
                if character_at(font[iy], ix + n * FONT_WIDTH) != ' '
                    fill_rect(left + (ix + i * FONT_WIDTH) * size - border, y - (FONT_HEIGHT - iy) * size - border,
                        size + border * 2, size + border * 2, color)

def draw_score()
    render_num_centered(get_screen_width() / 2, get_screen_height() - 10, 6, 2, score, 0x0)
    render_num_centered(get_screen_width() / 2, get_screen_height() - 10, 6, 0, score, 0xFFFFFF)

[export]
def initialize
    set_window_title("Match3 Chain")
    initField()
    score = 0

[export]
def act()
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    updateInput()
    return

[export]
def draw
    renderField()
    draw_score()
