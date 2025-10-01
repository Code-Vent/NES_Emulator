package screen

import "core:slice"
import "base:runtime"
import "core:mem"
import "core:fmt"
import win "core:sys/windows"
import "core:c"
import cart "./../mappers"

hWnd: win.HWND;
hdc: win.HDC;
hframe: win.HBITMAP;
framebuffer: [][WIDTH * PIXEL_SIZE]win.COLORREF;
background: [HEIGHT][WIDTH]win.COLORREF;
backdrop: [HEIGHT][WIDTH]win.COLORREF;
foreground: [HEIGHT][WIDTH]win.COLORREF;
PIXEL_SIZE::i32(4)
WIDTH::i32(256);
HEIGHT::i32(240);


// placeholder NES palette (64 RGB hex) - same as earlier placeholder
NES_PALETTE := [64]win.COLORREF {
    0x7C7C7C,0x0000FC,0x0000BC,0x4428BC,0x940084,0xA80020,0xA81000,0x881400,
    0x503000,0x007800,0x006800,0x005800,0x004058,0x000000,0x000000,0x000000,
    0xBCBCBC,0x0078F8,0x0058F8,0x6844FC,0xD800CC,0xE40058,0xF83800,0xE45C10,
    0xAC7C00,0x00B800,0x00A800,0x00A844,0x008888,0x000000,0x000000,0x000000,
    0xF8F8F8,0x3CBCFC,0x6888FC,0x9878F8,0xF878F8,0xF85898,0xF87858,0xFCA044,
    0xF8B800,0xB8F818,0x58D854,0x58F898,0x00E8D8,0x787878,0x000000,0x000000,
    0xFCFCFC,0xA4E4FC,0xB8B8F8,0xD8B8F8,0xF8B8F8,0xF8A4C0,0xF0D0B0,0xFCE0A8,
    0xF8D878,0xD8F878,0xB8F8B8,0xB8F8D8,0x00FCFC,0xF8D8F8,0x000000,0x000000
};

greyscale_palette := [2][4][4]u8{
    //Background Palettes
    {
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
    },
    //Sprite Palettes
    {
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
        {0x0F, 0x00, 0x10, 0x30,},
    },
};

create_frame ::proc(color: win.COLORREF) {
    width := WIDTH * PIXEL_SIZE;
    height := HEIGHT * PIXEL_SIZE;
    hdc_mem := win.CreateCompatibleDC(hdc);
    bmi := win.BITMAPINFO{};
    bmi.bmiHeader.biSize = size_of(win.BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width;
    bmi.bmiHeader.biHeight = -height;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = win.BI_RGB;
    
    ptr_buf:^rawptr;
    hframe = win.CreateDIBSection(hdc_mem, &bmi, win.DIB_RGB_COLORS, &ptr_buf, nil, 0);
    if hframe != nil && ptr_buf != nil {
        framebuffer = slice.from_ptr((^[WIDTH*PIXEL_SIZE]win.COLORREF)(ptr_buf), int(HEIGHT*PIXEL_SIZE));
        for i in 0..<height {
            for j in 0..<width {
                framebuffer[i][j] = color;
            }
        }
    }
}

init :: proc() {
    instance := win.HINSTANCE(win.GetModuleHandleW(nil));
    assert(instance != nil, "Failed to fetch the current instance");
    class_name := win.L("NES Emulator");

    cls := win.WNDCLASSW {
        lpfnWndProc = win_proc,
        lpszClassName = class_name,
        hInstance = instance,
    }

    class := win.RegisterClassW(&cls);
    assert(class != 0, "Class creation failed");
    
    hWnd = win.CreateWindowW(
        class_name,
        class_name,
        win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
        100, 100, 512, 480,
        nil, nil, instance, nil
    );
    assert(hWnd != nil, "Window creation failed");

    hdc = win.GetDC(hWnd);
}

win_proc ::proc "stdcall"(
    hwnd: win.HWND,
    msg: win.UINT,
    wparam: win.WPARAM,
    lparam: win.LPARAM
) -> win.LRESULT {
    context = runtime.default_context();
    switch msg {
        case win.WM_CREATE:
            
        case win.WM_PAINT:
            render_frame();
            ps: win.PAINTSTRUCT;            
            hdc := win.BeginPaint(hWnd, &ps);
            if hframe != nil {
                hdc_mem := win.CreateCompatibleDC(hdc);
                hOldBitmap := win.HBITMAP(win.SelectObject(hdc_mem, win.HGDIOBJ(hframe)));
                frame:win.BITMAP;
                win.GetObjectW(win.HANDLE(hframe), size_of(win.BITMAP), &frame);
                win.BitBlt(hdc, 0, 0, frame.bmWidth, frame.bmHeight, hdc_mem, 0, 0, win.SRCCOPY);
                win.SelectObject(hdc_mem, win.HGDIOBJ(hOldBitmap));
                win.DeleteDC(hdc_mem);
            }           
            win.EndPaint(hWnd, &ps);
        case win.WM_DESTROY:
            win.PostQuitMessage(0);
    }

    return win.DefWindowProcW(hwnd, msg, wparam, lparam);
}

view_pattern_table ::proc(
    self: ^Ppu2C02, 
    target: [][WIDTH]win.COLORREF, 
    backdrop_color: bool
) {  
    create_frame(win.RGB(255,0,255));
    for i in 0..<255 {
        draw_pattern_tbl_tile(self, u16(i), 0x0000, 0, 0, greyscale_palette[0][0], target, backdrop_color);
        draw_pattern_tbl_tile(self, u16(i), 0x1000, u16(WIDTH/2), 0, greyscale_palette[0][0], target, backdrop_color);
    }
    msg: win.MSG;
    for win.GetMessageW(&msg, nil, 0, 0) > 0 {
        win.TranslateMessage(&msg);
        win.DispatchMessageW(&msg);
    }
}

draw_pattern_tbl_tile ::proc(
    self: ^Ppu2C02, 
    tile_no: u16, 
    tbl_addr: u16,
    screen_offset_x: u16,
    screen_offset_y: u16,
    palette:[4]u8,
    target: [][WIDTH]win.COLORREF,
    backdrop_color: bool
) {

    tile:[8][8]u8;
    bd_tile:[8][8]u8; //Back drop tile

    src := cart.mapper_direct_access(self.mapper, tbl_addr + u16(tile_no * 16), 16);
    plane0 := src[0:8];
    plane1 := src[8:16];
    decode_tile_row(plane0, plane1, tile[:][:], palette, backdrop_color, bd_tile[:][:]);
    x0 := (tile_no % 16) * u16(8);
    y0 := (tile_no / 16) * u16(8);
    draw_tile(x0, y0, tile[:][:], screen_offset_x, screen_offset_y, target, backdrop_color, bd_tile[:][:]);
}

draw_tile ::proc(
    x, y: u16, //Origin
    tile:[][8]u8,
    screen_offset_x: u16, //x transform
    screen_offset_y: u16, // y transform
    target: [][WIDTH]win.COLORREF,
    backdrop_color: bool,
    bd_tile:[][8]u8,
) {
    x0 := x;
    y0 := y;
    for i in 0..<8 {
        xt := x0
        for j in 0..<8 {
            y_coord := y0 + screen_offset_y;
            x_coord := xt + screen_offset_x;
            palette_index := tile[i][j];
            if palette_index != 0 {
                color:win.COLORREF = NES_PALETTE[palette_index];
                target[y_coord][x_coord] = color;  
            }else if backdrop_color && bd_tile != nil{
                palette_index := bd_tile[i][j];
                color:win.COLORREF = NES_PALETTE[palette_index];
                backdrop[y_coord][x_coord] = color;  
            }else{
                color:win.COLORREF = NES_PALETTE[palette_index];
                backdrop[y_coord][x_coord] = color; 
            }           
            xt += 1;         
        }
        y0 += 1;
    }
}

decode_tile_row ::proc(
    plane0, plane1: []u8, 
    tile:[][8]u8, 
    palette:[4]u8,
    backdrop_color: bool,
    bd_tile:[][8]u8,
) {
    masks := [?]u8{128,64,32,16,8,4,2,1};
    palette_index:u8;
    for j in 0..<8 {
        for i in 0..<len(masks) {
            if masks[i] & plane0[j] == 0 {
                if masks[i] & plane1[j] == 0 {
                    palette_index = 0;
                }else{
                    palette_index = 1;
                }
            }else{
                if masks[i] & plane1[j] == 0 {
                    palette_index = 2;
                }else{
                    palette_index = 3;
                }
            }

            if palette_index != 0 {
                tile[j][i] = palette[palette_index];
            }else if backdrop_color {
                bd_tile[j][i] = palette[0];
            }
            
        }
    }
} 

render_frame ::proc() {
    for i in 0..<HEIGHT {
        for j in 0..<WIDTH {
            framebuffer[i][j] = backdrop[i][j];
        }
    }
}