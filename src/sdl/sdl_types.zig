
pub const RGBAColor = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,

    pub fn AsInt32(self:RGBAColor) u32 {
        return (self.r << 24) + (self.g << 16) + (self.b << 8) + .a;
    }
};