package pixel

Register ::enum(u8){
	R0=0, R1=1, R2=2, R3=3, R4=4, R5=5,
};

Register16 ::distinct Register;

Option ::enum{
	AND, OR, XOR,
	LSR, ASL, ROR, ROL,
	LDR,
	CMP,
};


Status ::distinct bit_set[StatusBits; u8];


StatusBits ::enum(u8){
	SPRITE_OVERFLOW, 
	SPRITE0HIT,
    VBLANK,
};

RenderSettings ::distinct bit_set[RenderBits; u8];

RenderBits ::enum(u8){
    GRAY_SCALE,
    LEFT_BCKGND,
    LEFT_SPRITE,
    BACKGROUND,
    SPRITES,
    RED_EMPHASIS,
    GREEN_EMPHASIS,
    BLUE_EMPHASIS,
}



RenderingState ::struct{
    nametable_addr :u16,
    vram_addr      :u16,
    scanline_no    :u16,
}

StateQueue ::struct{
    buffer :[128]RenderingState,
    front  :u8,
    back   :u8,
}

Pixel8 ::struct{
    rx   :[6]u8,
    rx16 :[6]u16,
    //temporary vram address 15-bit
    //fine x scroll 3-bit
    //toggle write
    state_queue      :StateQueue,
    status           :Status,
    render_settings  :RenderSettings,
}

lu_operation ::proc(
	pixel: ^Pixel8, 
	op: Option, 
	value: u16, 
	r: Register16
) -> (debug_info:string) {
    #partial switch op {
        case .AND:
            //TODO: Set some useful flags
            pixel.rx16[r] &= value;
        case .OR:
            //TODO: Set some useful flags
            pixel.rx16[r] |= value;
        case .XOR:
            //TODO: Set some useful flags
            pixel.rx16[r] ~= value;
        case .LDR:
            //TODO: Set some useful flags
            pixel.rx16[r] = value;
        case:
    }
    return debug_info;
}

enqueue_state ::proc(q: ^StateQueue, r: RenderingState) {

}

dequeue_state ::proc(q: ^StateQueue) -> RenderingState {
    return RenderingState{};
}

read_register ::proc(pixel: ^Pixel8, r: Register) -> u8 {
    return pixel.rx[r];
}

write_register ::proc(pixel: ^Pixel8, r: Register, value: u8) {
    pixel.rx[r] = value;
}

copy_register ::proc(pixel: ^Pixel8, from: Register16, to: Register16) {
	val := pixel.rx16[from];
    pixel.rx16[to] = val;
	//update_ZN_flags(calc, val);
}