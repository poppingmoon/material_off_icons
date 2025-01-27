import fontforge


def edit_font(source, target):
    font = fontforge.open(source)
    point = (70, 448)
    width = 27

    for glyph in font.glyphs():
        if glyph.unicode < 0xE000:
            continue
        glyph.removeOverlap()
        foreground = glyph.foreground.dup()
        glyphPen = glyph.glyphPen()
        glyphPen.moveTo((point[0] + width, point[1] + width))
        glyphPen.lineTo((point[1] + width, point[0] + width))
        glyphPen.lineTo((point[1] - width, point[0] - width))
        glyphPen.lineTo((point[0] - width, point[1] - width))
        glyphPen.closePath()
        mask = glyph.foreground.dup()
        glyph.foreground = mask.exclude(foreground)

        glyphPen = glyph.glyphPen(replace=False)
        glyphPen.moveTo((point[0], point[1]))
        glyphPen.lineTo((point[1], point[0]))
        glyphPen.lineTo((point[1] - width, point[0] - width))
        glyphPen.lineTo((point[0] - width, point[1] - width))
        glyphPen.closePath()
        glyph.removeOverlap()

    font.generate(target)


def main():
    flavors = ["Outlined", "Round", "Sharp"]
    edit_font(
        "material-design-icons/font/MaterialIcons-Regular.ttf",
        "assets/fonts/MaterialOffIcons-Regular.ttf",
    )
    for flavor in flavors:
        edit_font(
            f"material-design-icons/font/MaterialIcons{flavor}-Regular.otf",
            f"assets/fonts/MaterialOffIcons{flavor}-Regular.otf",
        )


if __name__ == "__main__":
    main()
