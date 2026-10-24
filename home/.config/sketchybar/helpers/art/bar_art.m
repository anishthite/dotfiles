// bar_art: renders a small animated math visual into PNG frames for a SketchyBar item.
// It animates while Spotify or Music is playing and freezes, dimmed, when paused.
//
// Usage: bar_art <item> <width> <height> <fps> <ink 0xAARRGGBB> <accent 0xAARRGGBB> <piece-file>
// The piece file holds one piece id (fourier, zeta, julia, clifford, harmonograph, lissajous, taylor);
// it is re-read on change.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#include <sys/stat.h>
#include "../event_providers/sketchybar.h"

#define DIR "/tmp/sketchybar_art"
#define SCALE 2  // device pixels per art pixel; the item shows the PNG at scale 0.5

static int W, H;
static uint32_t INK, ACCENT;
static char ITEM[128], PIECE_FILE[1024];
static float *buf;       // piece output: 0..1 ink intensity, 2..3 accent strength
static float *density;   // persistent state for the attractor
static uint8_t *tones;   // 0 off, 1 dim, 2 ink, 3 accent
static uint8_t *rgba;    // premultiplied RGBA at SCALE
static bool playing;
static char frame_path[256];

// ---- helpers ----

static double fract(double x) { return x - floor(x); }
static double clampd(double x, double a, double b) { return x < a ? a : x > b ? b : x; }

static double hash3(int a, int b, int c) {
  uint32_t h = ((uint32_t)a * 0x27d4eb2du) ^ ((uint32_t)(b + 0x9e37) * 0x165667b1u) ^ ((uint32_t)(c + 0x7f4a) * 0x2c1b3c6du);
  h = (h ^ (h >> 15)) * 0x85ebca6bu;
  h = (h ^ (h >> 13)) * 0xc2b2ae35u;
  return (h ^ (h >> 16)) / 4294967296.0;
}

static void clear(void) { memset(buf, 0, sizeof(float) * W * H); }

static void plot(double x, double y, double v) {
  int ix = (int)floor(x), iy = (int)floor(y);
  if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
  float *p = &buf[iy * W + ix];
  if (v >= 2 || (*p < 2 && v > *p)) *p = v;
}

static void line(double x0, double y0, double v0, double x1, double y1, double v1) {
  int n = (int)fmin(400, ceil(hypot(x1 - x0, y1 - y0) * 1.5) + 1);
  for (int i = 0; i <= n; i++) { double k = (double)i / n; plot(x0 + (x1 - x0) * k, y0 + (y1 - y0) * k, v0 + (v1 - v0) * k); }
}

static void ring(double cx, double cy, double r, double v) {
  for (double s = 0; s < 2 * M_PI; s += 0.7 / r) plot(cx + r * cos(s), cy + r * sin(s), v);
}

// ---- pieces: fill buf for time t; step advances stateful pieces by one frame ----

static void fourier(double t, bool step) {  // a square wave built from odd harmonics, drawn by epicycles
  clear();
  int terms = 1 + (int)fmod(t / 2.5, 7);  // 1..7 odd harmonics, then start over
  double w = 2 * M_PI * 0.35, R = H * 0.33, cy = H / 2.0, x = H / 2.0 + 1, y = cy, x0 = H * 1.6;
  for (int k = 1; k <= 2 * terms - 1; k += 2) {
    double r = R * 4 / (M_PI * k), a = k * w * t;
    if (r >= 1.5) ring(x, y, r, 0.35);
    double nx = x + r * cos(a), ny = y - r * sin(a);
    line(x, y, 0.8, nx, ny, 0.8);
    x = nx;
    y = ny;
  }
  for (double px = x + 2; px < x0; px += 2) plot(px, y, 0.35);  // dotted guide from the pen to the trace
  double prev = y;
  for (int px = (int)x0; px < W; px++) {  // the trace: older pen heights further right
    double tau = t - (px - x0) * 0.07, v = 0;
    for (int k = 1; k <= 2 * terms - 1; k += 2) v += R * 4 / (M_PI * k) * sin(k * w * tau);
    line(px - 1, prev, 1, px, cy - v, 1);
    prev = cy - v;
  }
  plot(x, y, 3);
}

static double riemann_siegel_z(double s) {  // Z(t) = e^{iθ(t)} ζ(1/2 + it), real; its sign changes are zeta's zeros
  double q = s / (2 * M_PI);
  double theta = s / 2 * log(q) - s / 2 - M_PI / 8 + 1 / (48 * s) + 7 / (5760 * s * s * s);
  int n = (int)floor(sqrt(q));
  double sum = 0;
  for (int k = 1; k <= n; k++) sum += cos(theta - s * log(k)) / sqrt(k);
  double p = sqrt(q) - n, c = cos(2 * M_PI * p);
  if (fabs(c) < 1e-9) { p += 1e-7; c = cos(2 * M_PI * p); }
  double c0 = cos(2 * M_PI * (p * p - p - 1.0 / 16)) / c;
  return 2 * sum + ((n - 1) % 2 ? -1 : 1) * pow(q, -0.25) * c0;
}

static void zeta(double t, bool step) {  // Z(t) scrolling along the critical line; zeros flash on the axis
  clear();
  static double scale = 3;
  double t0 = 14 + fmod(t * 0.6, 3000), z[W], peak = 0;
  for (int x = 0; x < W; x++) { z[x] = riemann_siegel_z(t0 + x * 0.18); peak = fmax(peak, fabs(z[x])); }
  scale += (fmax(2, peak) - scale) * 0.1;  // ease the vertical scale as the window moves
  double cy = H / 2.0, amp = (H / 2.0 - 1.5) / scale;
  for (int x = 0; x < W; x += 2) plot(x, cy, 0.35);
  for (int x = 1; x < W; x++) {
    line(x - 1, cy - z[x - 1] * amp, 1, x, cy - z[x] * amp, 1);
    if ((z[x - 1] < 0) != (z[x] < 0)) for (int d = -1; d <= 1; d++) plot(x, cy + d, 3);
  }
}

static void julia(double t, bool step) {  // a row of Julia sets, c walking the |c| = 0.7885 circle
  int n = (int)fmax(1, round(W / (H * 1.33)));
  double cell = (double)W / n, unit = 2.4 / H;  // one pixel in the complex plane; y spans ±1.2
  for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
    int k = (int)(x / cell);
    double cr = 0.7885 * cos(t * 0.25 + k * M_PI / 2), ci = 0.7885 * sin(t * 0.25 + k * M_PI / 2), v = 0;
    for (int s = 0; s < 4; s++) {  // 2×2 supersampling
      double zr = (x + 0.25 + 0.5 * (s & 1) - (k + 0.5) * cell) * unit, zi = (y + 0.25 + 0.5 * (s >> 1) - H / 2.0) * unit, r2 = 0;
      int i = 0;
      while (i < 80 && (r2 = zr * zr + zi * zi) < 16) { double nr = zr * zr - zi * zi + cr; zi = 2 * zr * zi + ci; zr = nr; i++; }
      double mu = i + 1 - log(log(sqrt(r2))) / M_LN2;
      v += 0.25 * (i == 80 ? 0.3 : clampd((mu - 4) / 18, 0, 1));  // edges glow; the filled set stays dim; far points stay dark
    }
    buf[y * W + x] = v > 0.92 ? 3 : v;
  }
}

static double attractor_x = 0.1, attractor_y = 0.1, attractor_skip = 0;

static int clifford_coverage(double a, double b, double c, double d) {  // distinct cells hit by a short orbit
  static uint8_t *hit;
  if (!hit) hit = malloc((size_t)W * H);
  memset(hit, 0, (size_t)W * H);
  double x = 0.1, y = 0.1, sx = W / (2 * (1 + fabs(c))), sy = H / (2 * (1 + fabs(d)));
  int n = 0;
  for (int i = 0; i < 5000; i++) {  // skip a long transient: orbits can wander before settling into a cycle
    double nx = sin(a * y) + c * cos(a * x), ny = sin(b * x) + d * cos(b * y);
    x = nx;
    y = ny;
    int px = (int)((x + 1 + fabs(c)) * sx), py = (int)((y + 1 + fabs(d)) * sy);
    if (i > 2000 && px >= 0 && px < W && py >= 0 && py < H && !hit[py * W + px]) { hit[py * W + px] = 1; n++; }
  }
  return n;
}

static void clifford(double t, bool step) {  // x' = sin(a y) + c cos(a x), y' = sin(b x) + d cos(b y)
  double a, b, c, d;
  // The parameters drift, but Clifford space is full of periodic windows where the orbit collapses
  // to a few dots; when a short orbit covers too little, skip the drift ahead past the window.
  for (int tries = 0;; tries++) {
    double pt = t + attractor_skip;
    a = 1.7 + 0.08 * sin(pt * 0.07);
    b = 1.7 + 0.08 * cos(pt * 0.05);
    c = 0.06 + 0.08 * sin(pt * 0.09);
    d = 1.2 + 0.08 * cos(pt * 0.11);
    if (!step || tries == 40 || clifford_coverage(a, b, c, d) >= W * H / 4) break;
    attractor_skip += 0.5;
  }
  if (step) {
    for (int i = 0; i < W * H; i++) density[i] *= 0.5;  // old density fades as the parameters drift
    double x = attractor_x, y = attractor_y, sx = W / (2 * (1 + fabs(c))), sy = H / (2 * (1 + fabs(d)));
    for (int i = 0; i < 25000; i++) {
      double nx = sin(a * y) + c * cos(a * x), ny = sin(b * x) + d * cos(b * y);
      x = nx;
      y = ny;
      int px = (int)((x + 1 + fabs(c)) * sx), py = (int)((y + 1 + fabs(d)) * sy);
      if (px >= 0 && px < W && py >= 0 && py < H) density[py * W + px] += 1;
    }
    attractor_x = x;
    attractor_y = y;
  }
  // Normalise to the typical cell, not the peak: orbits can linger in one cell and crush everything else.
  double sum = 0;
  int lit = 0;
  for (int i = 0; i < W * H; i++) if (density[i] > 0) { sum += density[i]; lit++; }
  double cap = fmax(1, 4 * sum / fmax(lit, 1)), norm = log1p(cap);
  for (int i = 0; i < W * H; i++) buf[i] = density[i] > 2 * cap ? 3 : pow(fmin(1, log1p(density[i]) / norm), 0.8);
}

static void harmonograph(double t, bool step) {  // rotary harmonograph: two damped circular pendulums; new figure every 30 s
  clear();
  static const double RATIOS[] = { 2, 3, 1.5, 4, 2.5 };
  int cycle = (int)(t / 30);
  double f = RATIOS[cycle % 5] + (hash3(cycle, 5, 0) - 0.5) * 0.03;  // a slight detune makes the rosette precess
  double p1 = hash3(cycle, 1, 0) * 2 * M_PI, p2 = hash3(cycle, 2, 0) * 2 * M_PI, turn = cycle % 2 ? -1 : 1;
  double end = 24 + 60 * fmod(t, 30) / 30, start = end - 24, px = 0, py = 0;
  double gain = 1 / (exp(-0.02 * start) + exp(-0.035 * start));  // keep the visible trail filling the strip
  for (double s = start; s < end; s += 0.02) {  // a fading pen trail; the whole figure is mush at 24px
    double e1 = exp(-0.02 * s), e2 = exp(-0.035 * s);
    double x = gain * (e1 * sin(s + p1) + e2 * sin(f * s + p2));
    double y = gain * (e1 * cos(s + p1) + turn * e2 * cos(f * s + p2));
    double sx = W / 2.0 + x * (W / 2.0 - 2), sy = H / 2.0 + y * (H / 2.0 - 1.5), v = pow((s - start) / 24, 1.5);
    if (s > start) line(px, py, v, sx, sy, v);
    px = sx;
    py = sy;
  }
  plot(px, py, 3);
}

static void lissajous(double t, bool step) {  // a row of Lissajous figures, phase drifting
  clear();
  static const int RATIOS[][2] = { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 3, 5 }, { 4, 5 }, { 5, 6 }, { 1, 3 }, { 2, 5 } };
  int n = (int)fmax(1, (W + 2) / (H + 2));
  double gap = n > 1 ? (W - n * H) / (double)(n - 1) : 0, r = H / 2.0 - 1;
  for (int k = 0; k < n; k++) {
    int a = RATIOS[k % 8][0], b = RATIOS[k % 8][1];
    double ox = k * (H + gap) + H / 2.0, oy = H / 2.0, phase = t * 0.6 + k * 0.4, px = 0, py = 0;
    for (int i = 0; i <= 240; i++) {
      double s = i / 240.0 * 2 * M_PI, x = ox + r * sin(a * s + phase), y = oy + r * sin(b * s);
      if (i) line(px, py, 0.9, x, y, 0.9);
      px = x;
      py = y;
    }
    plot(ox + r * sin(a * t * 1.5 + phase), oy + r * sin(b * t * 1.5), 3);
  }
}

static void taylor(double t, bool step) {  // sin x against its Taylor polynomials; agreement glows
  clear();
  int order = 1 + 2 * ((int)(t / 1.6) % 10);  // 1, 3, ..., 19
  double cy = H / 2.0, amp = H / 2.0 - 2, span = 3.2 * M_PI, prev = NAN;
  for (int x = 0; x < W; x++) {
    double u = (x + 0.5 - W / 2.0) / (W / 2.0) * span, s = sin(u), poly = 0, term = u;
    for (int k = 1; k <= order; k += 2) { poly += term; term *= -u * u / ((k + 1) * (k + 2)); }
    if (x % 2 == 0) plot(x, cy - s * amp, 0.35);  // sin x, dotted
    double py = fabs(poly) < 1.5 ? cy - poly * amp : NAN;  // diverging arms leave the strip
    double v = fabs(poly - s) < 0.03 ? 2.9 : 1;
    if (!isnan(py) && !isnan(prev)) line(x - 1, prev, v, x, py, v);
    prev = py;
  }
}

enum { THRESHOLD, BAYER4, BAYER8 };
typedef struct { const char *id; void (*draw)(double, bool); int dither; int warm; } Piece;
static const Piece PIECES[] = {
  { "fourier", fourier, THRESHOLD, 0 },
  { "zeta", zeta, THRESHOLD, 0 },
  { "julia", julia, BAYER8, 0 },
  { "clifford", clifford, BAYER4, 4 },
  { "harmonograph", harmonograph, THRESHOLD, 0 },
  { "lissajous", lissajous, THRESHOLD, 0 },
  { "taylor", taylor, THRESHOLD, 0 },
};
static const Piece *piece = &PIECES[0];

// ---- dithering and output ----

static const uint8_t B4[4][4] = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } };
static const uint8_t B8[8][8] = {
  { 0, 32, 8, 40, 2, 34, 10, 42 }, { 48, 16, 56, 24, 50, 18, 58, 26 },
  { 12, 44, 4, 36, 14, 46, 6, 38 }, { 60, 28, 52, 20, 62, 30, 54, 22 },
  { 3, 35, 11, 43, 1, 33, 9, 41 }, { 51, 19, 59, 27, 49, 17, 57, 25 },
  { 15, 47, 7, 39, 13, 45, 5, 37 }, { 63, 31, 55, 23, 61, 29, 53, 21 },
};

static void quantize(int mode) {
  for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
    int i = y * W + x;
    double v = buf[i], hot = 0, b4 = (B4[y & 3][x & 3] + 0.5) / 16;
    if (v >= 2) { hot = fmin(1, v - 2) + 1e-3; v = 0; } else v = clampd(v, 0, 1);
    double th = mode == BAYER4 ? b4 : mode == BAYER8 ? (B8[y & 7][x & 7] + 0.5) / 64 : 0.5;
    tones[i] = (uint8_t)fmin(2, floor(v * 2 + th));
    if (hot > 0 && hot + b4 > 1) tones[i] = 3;
  }
}

static void paint(bool dimmed) {
  uint8_t colors[4][4] = { { 0 } };
  double alpha[4] = { 0, 0.38, 1, 1 };
  uint32_t source[4] = { 0, INK, INK, ACCENT };
  for (int k = 1; k < 4; k++) {
    double a = ((source[k] >> 24) & 0xff) / 255.0 * alpha[k] * (dimmed ? 0.45 : 1);
    colors[k][0] = (uint8_t)round(((source[k] >> 16) & 0xff) * a);
    colors[k][1] = (uint8_t)round(((source[k] >> 8) & 0xff) * a);
    colors[k][2] = (uint8_t)round((source[k] & 0xff) * a);
    colors[k][3] = (uint8_t)round(255 * a);
  }
  int stride = W * SCALE * 4;
  for (int y = 0; y < H * SCALE; y++) for (int x = 0; x < W * SCALE; x++)
    memcpy(&rgba[y * stride + x * 4], colors[tones[(y / SCALE) * W + x / SCALE]], 4);
}

static bool write_png(const char *path) {
  char tmp[1100];
  snprintf(tmp, sizeof tmp, "%s.tmp", path);
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  CGContextRef ctx = CGBitmapContextCreate(rgba, W * SCALE, H * SCALE, 8, W * SCALE * 4, space,
                                           kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGImageRef image = CGBitmapContextCreateImage(ctx);
  CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)tmp, strlen(tmp), false);
  CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, CFSTR("public.png"), 1, NULL);
  bool ok = false;
  if (dest) {
    CGImageDestinationAddImage(dest, image, NULL);
    ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
  }
  CFRelease(url);
  CGImageRelease(image);
  CGContextRelease(ctx);
  CGColorSpaceRelease(space);
  return ok && rename(tmp, path) == 0;  // atomic swap, so SketchyBar never reads a half-written file
}

// ---- control ----

static bool load_piece(void) {  // true when the chosen piece changed
  static struct timespec seen;
  struct stat st;
  if (stat(PIECE_FILE, &st) != 0 || (st.st_mtimespec.tv_sec == seen.tv_sec && st.st_mtimespec.tv_nsec == seen.tv_nsec)) return false;
  seen = st.st_mtimespec;
  char id[64] = "";
  FILE *f = fopen(PIECE_FILE, "r");
  if (f) { if (fscanf(f, "%63s", id) != 1) id[0] = 0; fclose(f); }
  for (size_t i = 0; i < sizeof PIECES / sizeof *PIECES; i++) {
    if (strcmp(id, PIECES[i].id) == 0 && piece != &PIECES[i]) {
      piece = &PIECES[i];
      memset(density, 0, sizeof(float) * W * H);
      for (int w = 0; w < piece->warm; w++) piece->draw(0, true);
      return true;
    }
  }
  return false;
}

static bool query_playing(void) {  // initial state; afterwards the players' notifications keep it current
  NSTask *task = [NSTask new];
  task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
  NSString *script = @"if application \"Spotify\" is running then\n"
                      "  tell application \"Spotify\" to if player state is playing then return \"playing\"\n"
                      "end if\n"
                      "if application \"Music\" is running then\n"
                      "  tell application \"Music\" to if player state is playing then return \"playing\"\n"
                      "end if\n"
                      "return \"\"";
  task.arguments = @[ @"-e", script ];
  NSPipe *pipe = [NSPipe pipe];
  task.standardOutput = pipe;
  task.standardError = [NSFileHandle fileHandleWithNullDevice];
  if (![task launchAndReturnError:nil]) return false;
  [task waitUntilExit];
  NSString *out = [[NSString alloc] initWithData:[pipe.fileHandleForReading readDataToEndOfFile] encoding:NSUTF8StringEncoding];
  return [out containsString:@"playing"];
}

int main(int argc, char **argv) {
  @autoreleasepool {
    if (argc < 8) {
      printf("Usage: %s <item> <width> <height> <fps> <ink 0xAARRGGBB> <accent 0xAARRGGBB> <piece-file>\n", argv[0]);
      return 1;
    }
    snprintf(ITEM, sizeof ITEM, "%s", argv[1]);
    W = atoi(argv[2]);
    H = atoi(argv[3]);
    double fps = atof(argv[4]);
    INK = (uint32_t)strtoul(argv[5], NULL, 16);
    ACCENT = (uint32_t)strtoul(argv[6], NULL, 16);
    snprintf(PIECE_FILE, sizeof PIECE_FILE, "%s", argv[7]);
    if (W <= 0 || H <= 0 || W > 1024 || H > 256 || fps <= 0) return 1;

    mkdir(DIR, 0755);
    buf = calloc((size_t)W * H, sizeof(float));
    density = calloc((size_t)W * H, sizeof(float));
    tones = calloc((size_t)W * H, 1);
    rgba = calloc((size_t)W * H * SCALE * SCALE * 4, 1);

    if (getenv("BAR_ART_DUMP")) {  // debug: render every piece at time BAR_ART_DUMP, then exit
      double t = atof(getenv("BAR_ART_DUMP"));
      for (size_t i = 0; i < sizeof PIECES / sizeof *PIECES; i++) {
        memset(density, 0, sizeof(float) * W * H);
        for (int w = 0; w < PIECES[i].warm; w++) PIECES[i].draw(t, true);
        PIECES[i].draw(t, false);
        quantize(PIECES[i].dither);
        paint(false);
        snprintf(frame_path, sizeof frame_path, DIR "/dump_%s.png", PIECES[i].id);
        write_png(frame_path);
      }
      return 0;
    }

    load_piece();
    playing = query_playing();

    for (NSString *name in @[ @"com.spotify.client.PlaybackStateChanged", @"com.apple.Music.playerInfo" ]) {
      [[NSDistributedNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue mainQueue]
                                                               usingBlock:^(NSNotification *note) {
        playing = [note.userInfo[@"Player State"] isEqual:@"Playing"];
      }];
    }

    __block double t = 0, last = CFAbsoluteTimeGetCurrent(), checked = 0, sent = 0;
    __block bool dirty = true, was_playing = !playing;
    __block int parity = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 / fps repeats:YES block:^(NSTimer *timer) {
      double now = CFAbsoluteTimeGetCurrent(), dt = fmin(0.25, now - last);
      last = now;
      if (now - checked > 0.5) { checked = now; dirty |= load_piece(); }
      if (CGDisplayIsAsleep(CGMainDisplayID())) return;
      if (playing) t += dt;
      char message[512];
      if (playing || dirty || playing != was_playing) {
        piece->draw(t, playing);
        quantize(piece->dither);
        paint(!playing);
        parity ^= 1;  // alternate files so every --set points at a fresh image
        snprintf(frame_path, sizeof frame_path, DIR "/%s_%d.png", ITEM, parity);
        if (!write_png(frame_path)) return;
        dirty = false;
        was_playing = playing;
      } else if (now - sent < 3 || !frame_path[0]) {
        return;  // still: re-send every few seconds in case SketchyBar reloaded
      }
      snprintf(message, sizeof message, "--set %s background.image=%s", ITEM, frame_path);
      sketchybar(message);
      sent = now;
    }];
    [[NSRunLoop mainRunLoop] run];
  }
  return 0;
}
