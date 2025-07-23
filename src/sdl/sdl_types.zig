
pub const RGBAColor = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,

    pub fn AsInt32() u32 {
        return (.r << 24) + (.g << 16) + (.b << 8) + .a;
    }
};