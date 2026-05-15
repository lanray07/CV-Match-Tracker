from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "AppStoreScreenshots"
ICON = ROOT / "CVMatchTracker" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
FONT_DIR = Path("C:/Windows/Fonts")


COLORS = {
    "bg": (238, 242, 247),
    "ink": (20, 28, 38),
    "muted": (98, 111, 128),
    "tertiary": (142, 151, 164),
    "card": (255, 255, 255),
    "surface": (247, 249, 252),
    "border": (221, 227, 235),
    "blue": (10, 132, 255),
    "orange": (255, 149, 0),
    "green": (52, 199, 89),
    "red": (255, 59, 48),
    "purple": (112, 76, 255),
    "nav": (248, 250, 253),
}


def load_font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    file_name = {
        "regular": "segoeui.ttf",
        "bold": "segoeuib.ttf",
        "semibold": "segoeuib.ttf",
        "light": "segoeuil.ttf",
    }.get(weight, "segoeui.ttf")
    return ImageFont.truetype(str(FONT_DIR / file_name), size)


class Canvas:
    def __init__(self, width: int, height: int, scale: int):
        self.width = width
        self.height = height
        self.scale = scale
        self.image = Image.new("RGB", (width, height), COLORS["bg"])
        self.draw = ImageDraw.Draw(self.image)

    def s(self, value: float) -> int:
        return int(round(value * self.scale))

    def xy(self, values: Iterable[float]) -> tuple[int, ...]:
        return tuple(self.s(v) for v in values)

    def font(self, size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
        return load_font(self.s(size), weight)

    def rounded(
        self,
        x: float,
        y: float,
        w: float,
        h: float,
        r: float,
        fill: tuple[int, int, int],
        outline: tuple[int, int, int] | None = None,
        width: float = 1,
    ) -> None:
        self.draw.rounded_rectangle(
            self.xy((x, y, x + w, y + h)),
            radius=self.s(r),
            fill=fill,
            outline=outline,
            width=max(1, self.s(width)) if outline else 1,
        )

    def rect(self, x: float, y: float, w: float, h: float, fill: tuple[int, int, int]) -> None:
        self.draw.rectangle(self.xy((x, y, x + w, y + h)), fill=fill)

    def line(self, x1: float, y1: float, x2: float, y2: float, fill: tuple[int, int, int], width: float = 1) -> None:
        self.draw.line(self.xy((x1, y1, x2, y2)), fill=fill, width=max(1, self.s(width)))

    def text(
        self,
        x: float,
        y: float,
        value: str,
        size: int,
        weight: str = "regular",
        fill: tuple[int, int, int] = COLORS["ink"],
        max_width: float | None = None,
        line_height: float = 1.18,
        max_lines: int | None = None,
        align: str = "left",
    ) -> float:
        font = self.font(size, weight)
        lines = self.wrap(value, font, self.s(max_width) if max_width else None)
        if max_lines is not None and len(lines) > max_lines:
            lines = lines[:max_lines]
            while lines[-1] and self.draw.textlength(lines[-1] + "...", font=font) > (self.s(max_width) if max_width else 10**9):
                lines[-1] = lines[-1][:-1]
            lines[-1] = lines[-1].rstrip() + "..."
        py = self.s(y)
        line_px = int(font.size * line_height)
        for line in lines:
            px = self.s(x)
            if align == "center" and max_width:
                px = self.s(x) + (self.s(max_width) - int(self.draw.textlength(line, font=font))) // 2
            self.draw.text((px, py), line, font=font, fill=fill)
            py += line_px
        return py / self.scale

    def wrap(self, value: str, font: ImageFont.FreeTypeFont, max_width: int | None) -> list[str]:
        if max_width is None:
            return value.split("\n")
        lines: list[str] = []
        for paragraph in value.split("\n"):
            words = paragraph.split()
            if not words:
                lines.append("")
                continue
            current = words[0]
            for word in words[1:]:
                candidate = f"{current} {word}"
                if self.draw.textlength(candidate, font=font) <= max_width:
                    current = candidate
                else:
                    lines.append(current)
                    current = word
            lines.append(current)
        return lines

    def paste_icon(self, x: float, y: float, size: float) -> None:
        if not ICON.exists():
            self.rounded(x, y, size, size, 12, COLORS["blue"])
            self.text(x + size * 0.22, y + size * 0.22, "CV", 18, "bold", (255, 255, 255))
            return
        icon = Image.open(ICON).convert("RGBA").resize((self.s(size), self.s(size)), Image.LANCZOS)
        self.image.paste(icon.convert("RGB"), self.xy((x, y)), icon)


def headline(canvas: Canvas, title: str, subtitle: str) -> None:
    canvas.paste_icon(24, 26, 42)
    canvas.text(76, 26, "CV Match Tracker", 15, "semibold", COLORS["muted"])
    canvas.text(24, 75, title, 29, "bold", COLORS["ink"], max_width=360, line_height=1.08, max_lines=2)
    canvas.text(24, 143, subtitle, 14, "regular", COLORS["muted"], max_width=360, max_lines=2)


def shell(canvas: Canvas, title: str, active_tab: str) -> tuple[float, float, float, float]:
    logical_w = canvas.width / canvas.scale
    if logical_w < 700:
        x, y, w, h = 20, 218, logical_w - 40, 646
        radius = 34
        nav_h, tab_h = 84, 66
        canvas.rounded(x + 3, y + 7, w, h, radius, (213, 222, 234))
        canvas.rounded(x, y, w, h, radius, (255, 255, 255), COLORS["border"], 1)
        canvas.rect(x + 1, y + 50, w - 2, h - 50 - tab_h, COLORS["surface"])
        canvas.rounded(x, y, w, 58, radius, COLORS["nav"])
        canvas.text(x + 22, y + 16, "9:41", 13, "semibold")
        canvas.text(x + w - 88, y + 16, "5G  100%", 12, "semibold", COLORS["ink"])
        canvas.text(x + 22, y + 54, title, 19, "bold")
        canvas.line(x, y + nav_h, x + w, y + nav_h, COLORS["border"])
        canvas.line(x, y + h - tab_h, x + w, y + h - tab_h, COLORS["border"])
        draw_tabs(canvas, x, y + h - tab_h, w, tab_h, active_tab)
        return x + 18, y + nav_h + 16, w - 36, h - nav_h - tab_h - 28

    x, y, w, h = 72, 226, logical_w - 144, 1070
    radius = 28
    nav_h, tab_h = 86, 72
    canvas.rounded(x + 5, y + 9, w, h, radius, (213, 222, 234))
    canvas.rounded(x, y, w, h, radius, (255, 255, 255), COLORS["border"], 1)
    canvas.rect(x + 1, y + 54, w - 2, h - 54 - tab_h, COLORS["surface"])
    canvas.rounded(x, y, w, 60, radius, COLORS["nav"])
    canvas.text(x + 24, y + 17, "9:41", 14, "semibold")
    canvas.text(x + w - 96, y + 17, "Wi-Fi  100%", 13, "semibold")
    canvas.text(x + 26, y + 54, title, 22, "bold")
    canvas.line(x, y + nav_h, x + w, y + nav_h, COLORS["border"])
    canvas.line(x, y + h - tab_h, x + w, y + h - tab_h, COLORS["border"])
    draw_tabs(canvas, x, y + h - tab_h, w, tab_h, active_tab)
    return x + 30, y + nav_h + 24, w - 60, h - nav_h - tab_h - 44


def draw_tabs(canvas: Canvas, x: float, y: float, w: float, h: float, active: str) -> None:
    tabs = [("Dashboard", "D"), ("Apps", "A"), ("CV Library", "CV"), ("Call Match", "C"), ("Settings", "S")]
    tab_w = w / len(tabs)
    for index, (label, glyph) in enumerate(tabs):
        cx = x + index * tab_w
        color = COLORS["blue"] if label == active else COLORS["tertiary"]
        canvas.text(cx, y + 10, glyph, 13, "bold", color, max_width=tab_w, align="center")
        canvas.text(cx, y + 35, label, 10, "semibold", color, max_width=tab_w, align="center")


def badge(canvas: Canvas, x: float, y: float, value: str, color: tuple[int, int, int]) -> None:
    width = 10 + len(value) * 6.2
    canvas.rounded(x, y, width, 24, 12, tint(color, 0.12))
    canvas.text(x + 8, y + 5, value, 10, "semibold", color)


def tint(color: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(int(255 - (255 - channel) * amount) for channel in color)


def card(canvas: Canvas, x: float, y: float, w: float, h: float) -> None:
    canvas.rounded(x, y, w, h, 8, COLORS["card"], COLORS["border"], 1)


def small_icon(canvas: Canvas, x: float, y: float, label: str, color: tuple[int, int, int]) -> None:
    canvas.rounded(x, y, 34, 34, 8, tint(color, 0.14))
    canvas.text(x, y + 8, label, 10, "bold", color, max_width=34, align="center")


def draw_dashboard(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    canvas.text(x, y, "CV Match Tracker", 26, "bold", max_width=w)
    canvas.text(x, y + 34, "Find the exact CV, cover letter, and job description behind every application.", 12, fill=COLORS["muted"], max_width=w, max_lines=2)

    if h < 600:
        gap = 10
        cw = (w - gap) / 2
        stat_compact(canvas, x, y + 76, cw, "3", "Total applications", COLORS["blue"])
        stat_compact(canvas, x + cw + gap, y + 76, cw, "3", "Upcoming", COLORS["orange"])
        statuses = [("Applied", "1", COLORS["blue"]), ("Interviewing", "1", COLORS["orange"]), ("Offer", "0", COLORS["green"]), ("Rejected", "1", COLORS["red"])]
        sy = y + 152
        for row in range(2):
            for col in range(2):
                name, value, color = statuses[row * 2 + col]
                status_chip(canvas, x + col * (cw + gap), sy + row * 42, cw, name, value, color)
        canvas.text(x, y + 254, "Quick search", 15, "semibold")
        canvas.rounded(x, y + 284, w, 40, 8, COLORS["card"], COLORS["border"])
        canvas.text(x + 14, y + 296, "Maya Patel", 12, fill=COLORS["muted"])
        canvas.text(x, y + 344, "Upcoming follow-ups", 15, "semibold")
        reminder(canvas, x, y + 376, w, "Prepare for Acme phone screen", "Senior Product Manager at Acme Analytics", "May 17, 2026", COLORS["orange"])
        return

    gap = 10
    cw = (w - gap) / 2
    stat(canvas, x, y + 82, cw, "3", "Total applications", "F", COLORS["blue"])
    stat(canvas, x + cw + gap, y + 82, cw, "3", "Upcoming", "B", COLORS["orange"])

    statuses = [("Applied", "1", COLORS["blue"]), ("Interviewing", "1", COLORS["orange"]), ("Offer", "0", COLORS["green"]), ("Rejected", "1", COLORS["red"])]
    sy = y + 184
    for row in range(2):
        for col in range(2):
            name, value, color = statuses[row * 2 + col]
            sx = x + col * (cw + gap)
            stat(canvas, sx, sy + row * 94, cw, value, name, "S", color, compact=True)

    qy = sy + 204
    canvas.text(x, qy, "Quick search", 15, "semibold")
    canvas.rounded(x, qy + 30, w, 44, 8, COLORS["card"], COLORS["border"])
    canvas.text(x + 14, qy + 43, "Maya Patel", 13, fill=COLORS["muted"])

    canvas.text(x, qy + 98, "Upcoming follow-ups and interviews", 15, "semibold", max_width=w)
    reminder(canvas, x, qy + 130, w, "Prepare for Acme phone screen", "Senior Product Manager at Acme Analytics", "May 17, 2026", COLORS["orange"])
    reminder(canvas, x, qy + 218, w, "Follow up with Northstar", "Operations Manager at Northstar Health", "May 18, 2026", COLORS["blue"])


def stat(canvas: Canvas, x: float, y: float, w: float, value: str, title: str, glyph: str, color: tuple[int, int, int], compact: bool = False) -> None:
    h = 84 if compact else 92
    card(canvas, x, y, w, h)
    small_icon(canvas, x + 12, y + 12, glyph, color)
    canvas.text(x + 58, y + 15, value, 22, "bold")
    canvas.text(x + 58, y + 46, title, 10, fill=COLORS["muted"], max_width=w - 70, max_lines=2)


def stat_compact(canvas: Canvas, x: float, y: float, w: float, value: str, title: str, color: tuple[int, int, int]) -> None:
    card(canvas, x, y, w, 62)
    canvas.text(x + 12, y + 10, value, 20, "bold")
    canvas.text(x + 12, y + 37, title, 9, fill=COLORS["muted"], max_width=w - 24, max_lines=1)
    canvas.draw.ellipse(canvas.xy((x + w - 28, y + 12, x + w - 14, y + 26)), fill=color)


def status_chip(canvas: Canvas, x: float, y: float, w: float, title: str, value: str, color: tuple[int, int, int]) -> None:
    card(canvas, x, y, w, 34)
    canvas.text(x + 10, y + 8, value, 12, "bold", color)
    canvas.text(x + 30, y + 9, title, 9, "semibold", COLORS["muted"], max_width=w - 38, max_lines=1)


def reminder(canvas: Canvas, x: float, y: float, w: float, title: str, app: str, due: str, color: tuple[int, int, int]) -> None:
    card(canvas, x, y, w, 76)
    small_icon(canvas, x + 12, y + 18, "R", color)
    canvas.text(x + 58, y + 14, title, 13, "semibold", max_width=w - 76, max_lines=1)
    canvas.text(x + 58, y + 34, app, 10, fill=COLORS["muted"], max_width=w - 76, max_lines=1)
    canvas.text(x + 58, y + 52, due, 9, fill=COLORS["tertiary"])


def draw_call_match(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    canvas.text(x, y, "Match an incoming call to the exact application record.", 18, "bold", max_width=w, max_lines=2)
    canvas.text(x, y + 54, "Search company, role, recruiter or phone before you answer.", 12, fill=COLORS["muted"], max_width=w)
    canvas.rounded(x, y + 98, w, 44, 8, COLORS["card"], COLORS["border"])
    canvas.text(x + 14, y + 111, "+44 7700 900123", 13, "semibold")
    segmented(canvas, x, y + 156, w, ["All", "Company", "Job", "Phone"], "Phone")

    ry = y + 214
    compact = h < 600
    card_h = 242 if compact else 300
    card(canvas, x, ry, w, card_h)
    canvas.text(x + 16, ry + 16, "Acme Analytics", 20, "bold")
    canvas.text(x + 16, ry + 45, "Senior Product Manager", 12, fill=COLORS["muted"])
    badge(canvas, x + w - 108, ry + 18, "Interviewing", COLORS["orange"])
    canvas.line(x + 16, ry + 78, x + w - 16, ry + 78, COLORS["border"])
    match_line(canvas, x + 18, ry + 98, "CV sent", "Product Manager CV - SaaS", COLORS["blue"])
    match_line(canvas, x + 18, ry + 148, "Cover letter", "Acme Senior PM Cover Letter", COLORS["blue"])
    if compact:
        canvas.text(x + 18, ry + 204, "Recruiter: Maya Patel  +44 7700 900123", 10, "semibold", COLORS["green"], max_width=w - 36, max_lines=1)
    else:
        match_line(canvas, x + 18, ry + 198, "Recruiter", "Maya Patel  +44 7700 900123", COLORS["green"])
        canvas.text(x + 18, ry + 248, "Own onboarding and customer insights roadmap for a B2B SaaS platform.", 10, fill=COLORS["muted"], max_width=w - 36, max_lines=2)


def segmented(canvas: Canvas, x: float, y: float, w: float, values: list[str], active: str) -> None:
    canvas.rounded(x, y, w, 36, 8, (230, 235, 242))
    seg_w = w / len(values)
    for index, value in enumerate(values):
        sx = x + index * seg_w
        if value == active:
            canvas.rounded(sx + 3, y + 3, seg_w - 6, 30, 7, COLORS["card"])
            fill = COLORS["ink"]
        else:
            fill = COLORS["muted"]
        canvas.text(sx, y + 9, value, 10, "semibold", fill, max_width=seg_w, align="center")


def match_line(canvas: Canvas, x: float, y: float, title: str, value: str, color: tuple[int, int, int]) -> None:
    small_icon(canvas, x, y, "D", color)
    canvas.text(x + 48, y + 2, title, 10, fill=COLORS["muted"])
    canvas.text(x + 48, y + 20, value, 13, "semibold", max_width=260, max_lines=1)


def draw_application_detail(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    compact = h < 600
    header_h = 126 if compact else 152
    card(canvas, x, y, w, header_h)
    title_size = 16 if compact else 21
    title_width = w - 132 if compact else w - 32
    canvas.text(x + 16, y + 16, "Senior Product Manager", title_size, "bold", max_width=title_width, max_lines=1)
    canvas.text(x + 16, y + 48, "Acme Analytics", 13, fill=COLORS["muted"])
    badge(canvas, x + w - 108, y + 18, "Interviewing", COLORS["orange"])
    if compact:
        canvas.text(x + 16, y + 82, "May 6, 2026   London / Hybrid", 10, fill=COLORS["muted"], max_width=w - 32)
        canvas.text(x + 16, y + 102, "GBP 75k-90k", 10, fill=COLORS["muted"])
    else:
        segmented(canvas, x + 16, y + 82, w - 32, ["Applied", "Interview", "Offer"], "Interview")
        canvas.text(x + 16, y + 126, "May 6, 2026   London / Hybrid   GBP 75k-90k", 10, fill=COLORS["muted"], max_width=w - 32)

    docs_y = y + (150 if compact else 176)
    canvas.text(x, docs_y, "Documents", 15, "semibold")
    document_row(canvas, x, docs_y + 32, w, "CV version sent", "Product Manager CV - SaaS", "PDF stored locally")
    document_row(canvas, x, docs_y + 110, w, "Cover letter sent", "Acme Senior PM Cover Letter", "PDF stored locally")
    rec_y = docs_y + (204 if compact else 206)
    canvas.text(x, rec_y, "Recruiter", 15, "semibold")
    card(canvas, x, rec_y + 32, w, 78)
    canvas.text(x + 16, rec_y + 45, "Maya Patel", 13, "semibold")
    canvas.text(x + 16, rec_y + 66, "+44 7700 900123", 12, fill=COLORS["muted"])
    canvas.text(x + 16, rec_y + 86, "maya.patel@acme.example", 11, fill=COLORS["muted"], max_width=w - 32, max_lines=1)
    if not compact:
        canvas.text(x, y + 526, "Timeline", 15, "semibold")
        timeline_row(canvas, x, y + 558, w, "Recruiter phone screen booked", "Maya confirmed a 30 minute call.")


def document_row(canvas: Canvas, x: float, y: float, w: float, title: str, file_name: str, detail: str) -> None:
    card(canvas, x, y, w, 66)
    small_icon(canvas, x + 12, y + 16, "PDF", COLORS["blue"])
    canvas.text(x + 58, y + 12, title, 12, "semibold")
    canvas.text(x + 58, y + 32, file_name, 10, fill=COLORS["muted"], max_width=w - 78, max_lines=1)
    canvas.text(x + 58, y + 48, detail, 9, fill=COLORS["tertiary"])


def timeline_row(canvas: Canvas, x: float, y: float, w: float, title: str, detail: str) -> None:
    card(canvas, x, y, w, 76)
    canvas.draw.ellipse(canvas.xy((x + 17, y + 18, x + 28, y + 29)), fill=COLORS["blue"])
    canvas.text(x + 42, y + 13, title, 12, "semibold", max_width=w - 56, max_lines=1)
    canvas.text(x + 42, y + 34, detail, 10, fill=COLORS["muted"], max_width=w - 56, max_lines=2)


def draw_cv_library(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    canvas.text(x, y, "CV Library", 24, "bold")
    canvas.text(x, y + 34, "Store CV versions and see exactly which jobs used each one.", 12, fill=COLORS["muted"], max_width=w, max_lines=2)
    cv_card(canvas, x, y + 84, w, "Product Manager CV - SaaS", "Product_Manager_SaaS_CV.pdf", "2 jobs", "Recently used for Senior Product Manager at Acme Analytics")
    cv_card(canvas, x, y + 214, w, "Operations CV - Process Improvement", "Operations_Process_CV.pdf", "1 job", "Recently used for Operations Manager at Northstar Health")
    if h < 600:
        canvas.text(x, y + 356, "Jobs using this CV", 15, "semibold")
        document_row(canvas, x, y + 388, w, "Attached application", "Senior Product Manager at Acme Analytics", "Interviewing")
    else:
        canvas.text(x, y + 366, "PDF preview", 15, "semibold")
        card(canvas, x, y + 398, w, 190)
        canvas.rounded(x + 24, y + 420, w - 48, 146, 6, (250, 251, 253), COLORS["border"])
        canvas.text(x + 42, y + 444, "Product Manager CV - SaaS", 15, "bold")
        canvas.text(x + 42, y + 478, "Senior product manager with 7 years building B2B SaaS workflow products.", 10, fill=COLORS["muted"], max_width=w - 84, max_lines=2)
        canvas.text(x + 42, y + 528, "Highlights: discovery, roadmap, analytics, onboarding.", 10, fill=COLORS["muted"], max_width=w - 84)


def cv_card(canvas: Canvas, x: float, y: float, w: float, name: str, file_name: str, jobs: str, recent: str) -> None:
    card(canvas, x, y, w, 112)
    small_icon(canvas, x + 14, y + 16, "CV", COLORS["blue"])
    canvas.text(x + 62, y + 14, name, 14, "semibold", max_width=w - 80, max_lines=1)
    canvas.text(x + 62, y + 37, file_name, 10, fill=COLORS["muted"], max_width=w - 80, max_lines=1)
    canvas.text(x + 62, y + 61, jobs + "   PDF stored locally", 10, fill=COLORS["muted"])
    canvas.text(x + 14, y + 86, recent, 10, fill=COLORS["muted"], max_width=w - 28, max_lines=1)


def draw_add_application(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    canvas.text(x, y, "Add Application", 24, "bold")
    canvas.text(x, y + 34, "Capture company, recruiter, documents and the full job description offline.", 12, fill=COLORS["muted"], max_width=w, max_lines=2)
    if h < 600:
        form_section(canvas, x, y + 78, w, "Role", [("Company name", "Acme Analytics"), ("Job title", "Senior Product Manager")])
        form_section(canvas, x, y + 198, w, "Recruiter", [("Recruiter name", "Maya Patel"), ("Phone number", "+44 7700 900123")])
        form_section(canvas, x, y + 318, w, "Documents", [("Upload CV file", "Product Manager CV - SaaS"), ("Cover letter", "Acme Senior PM Cover Letter")])
        canvas.rounded(x, y + 438, w, 40, 8, COLORS["blue"])
        canvas.text(x, y + 449, "Save Application", 13, "bold", (255, 255, 255), max_width=w, align="center")
    else:
        form_section(canvas, x, y + 86, w, "Role", [("Company name", "Acme Analytics"), ("Job title", "Senior Product Manager"), ("Location", "London / Hybrid")])
        form_section(canvas, x, y + 250, w, "Recruiter", [("Recruiter name", "Maya Patel"), ("Phone number", "+44 7700 900123"), ("Email", "maya.patel@acme.example")])
        form_section(canvas, x, y + 414, w, "Documents", [("Upload CV file", "Product Manager CV - SaaS"), ("Upload cover letter file", "Acme Senior PM Cover Letter")])
        canvas.rounded(x, y + 568, w, 42, 8, COLORS["blue"])
        canvas.text(x, y + 579, "Save Application", 13, "bold", (255, 255, 255), max_width=w, align="center")


def form_section(canvas: Canvas, x: float, y: float, w: float, title: str, fields: list[tuple[str, str]]) -> None:
    canvas.text(x, y, title, 14, "semibold")
    card(canvas, x, y + 28, w, 46 * len(fields) + 10)
    fy = y + 40
    for label, value in fields:
        canvas.text(x + 14, fy, label, 9, fill=COLORS["muted"])
        canvas.text(x + 14, fy + 15, value, 12, "semibold", max_width=w - 28, max_lines=1)
        fy += 46


def draw_reminders(canvas: Canvas, content: tuple[float, float, float, float]) -> None:
    x, y, w, h = content
    canvas.text(x, y, "Reminders", 24, "bold")
    canvas.text(x, y + 34, "Keep follow-ups, interviews and response deadlines visible.", 12, fill=COLORS["muted"], max_width=w)
    reminder(canvas, x, y + 84, w, "Prepare for Acme phone screen", "Review CV version and product analytics examples.", "May 17, 2026", COLORS["orange"])
    reminder(canvas, x, y + 176, w, "Follow up with Northstar", "Ask whether the first round shortlist has been completed.", "May 18, 2026", COLORS["blue"])
    reminder(canvas, x, y + 268, w, "Response deadline", "Hiring team said feedback is expected by this date.", "May 21, 2026", COLORS["green"])
    if h < 600:
        return
    canvas.text(x, y + 392, "Quick notes before a call", 15, "semibold")
    card(canvas, x, y + 424, w, 132)
    canvas.text(x + 16, y + 442, "Recruiter: Maya Patel  +44 7700 900123", 12, "semibold", max_width=w - 32)
    canvas.text(x + 16, y + 470, "Status: Interviewing. Applied on May 6, 2026.", 11, fill=COLORS["muted"], max_width=w - 32)
    canvas.text(x + 16, y + 498, "Salary: GBP 75,000 - GBP 90,000.", 11, fill=COLORS["muted"], max_width=w - 32)


SCENES = [
    ("01-dashboard", "Track every application at a glance", "Statuses, reminders and quick search in one clean dashboard.", "Dashboard", "Dashboard", draw_dashboard),
    ("02-call-match", "Know what you sent when they call", "Search by phone, recruiter, company or role and pull up the exact CV.", "Call Match", "Call Match", draw_call_match),
    ("03-application-detail", "Every application record in one place", "See the CV, cover letter, recruiter, job description and timeline.", "Acme Analytics", "Apps", draw_application_detail),
    ("04-cv-library", "Organise every CV version", "Store tailored CVs and see which jobs each version was used for.", "CV Library", "CV Library", draw_cv_library),
    ("05-add-application", "Save the full application context", "Capture documents, recruiter details, notes and job descriptions offline.", "Add Application", "Apps", draw_add_application),
    ("06-reminders", "Never miss a follow-up", "Track interviews, response deadlines and notes before every call.", "Reminders", "Dashboard", draw_reminders),
]


def render_family(folder: str, width: int, height: int, scale: int) -> None:
    target = OUT / folder
    target.mkdir(parents=True, exist_ok=True)
    for file_stem, headline_text, subtitle, nav_title, active_tab, renderer in SCENES:
        canvas = Canvas(width, height, scale)
        headline(canvas, headline_text, subtitle)
        content = shell(canvas, nav_title, active_tab)
        renderer(canvas, content)
        canvas.image.save(target / f"{file_stem}.png", "PNG", optimize=True)


def main() -> None:
    render_family("iPhone-6.5", 1242, 2688, 3)
    render_family("iPad-12.9", 2048, 2732, 2)


if __name__ == "__main__":
    main()
