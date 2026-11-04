// Minimal GhosttyLib macOS link + draw proof.
// Links wwn-ghostty#libghostty-macos (ghostty-internal.a). Not the product
// Terminal paint path (still GhosttyGpu until ABI swap in Wawona tip).
//
// Prove:
//   nix build .#libghostty-macos-draw-proof -L
//   ./result/bin/libghostty-macos-draw-proof
//   nm -gU ./result/bin/libghostty-macos-draw-proof | rg 'ghostty_surface_draw'

#import <AppKit/AppKit.h>
#include <ghostty.h>
#include <stdio.h>

static void wakeup_cb(void *ud) { (void)ud; }

static bool action_cb(ghostty_app_t app, ghostty_target_s target,
                      ghostty_action_s action) {
  (void)app;
  (void)target;
  (void)action;
  return true;
}

static ghostty_clipboard_read_result_e read_clipboard_cb(
    void *ud, ghostty_clipboard_e clip, void *req, const char *const *mimes,
    size_t mime_count, bool confirmed) {
  (void)ud;
  (void)clip;
  (void)req;
  (void)mimes;
  (void)mime_count;
  (void)confirmed;
  return GHOSTTY_CLIPBOARD_READ_UNAVAILABLE;
}

static void confirm_read_clipboard_cb(void *ud,
                                      const ghostty_clipboard_confirm_s *c,
                                      void *req,
                                      ghostty_clipboard_request_e r) {
  (void)ud;
  (void)c;
  (void)req;
  (void)r;
}

static void write_clipboard_cb(void *ud, ghostty_clipboard_e clip,
                               const ghostty_clipboard_content_s *contents,
                               size_t contents_len, bool confirmed) {
  (void)ud;
  (void)clip;
  (void)contents;
  (void)contents_len;
  (void)confirmed;
}

static void close_surface_cb(void *ud, bool force) {
  (void)ud;
  (void)force;
}

int main(int argc, char **argv) {
  @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    int rc = ghostty_init((uintptr_t)argc, argv);
    fprintf(stderr, "ghostty_init=%d\n", rc);
    if (rc != GHOSTTY_SUCCESS) {
      return 2;
    }

    ghostty_config_t cfg = ghostty_config_new();
    if (!cfg) {
      fprintf(stderr, "config_new failed\n");
      return 3;
    }
    ghostty_config_load_default_files(cfg);
    ghostty_config_finalize(cfg);

    ghostty_runtime_config_s runtime = {
        .userdata = NULL,
        .supports_selection_clipboard = false,
        .wakeup_cb = wakeup_cb,
        .action_cb = action_cb,
        .read_clipboard_cb = read_clipboard_cb,
        .confirm_read_clipboard_cb = confirm_read_clipboard_cb,
        .write_clipboard_cb = write_clipboard_cb,
        .close_surface_cb = close_surface_cb,
    };

    ghostty_app_t app = ghostty_app_new(&runtime, cfg);
    if (!app) {
      fprintf(stderr, "app_new failed\n");
      return 4;
    }

    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 640, 400)
                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                    backing:NSBackingStoreBuffered
                      defer:NO];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 640, 400)];
    view.wantsLayer = YES;
    win.contentView = view;
    [win orderFrontRegardless];

    ghostty_surface_config_s sc = ghostty_surface_config_new();
    sc.platform_tag = GHOSTTY_PLATFORM_MACOS;
    sc.platform.macos.nsview = (__bridge void *)view;
    sc.userdata = (__bridge void *)view;
    sc.scale_factor = 2.0;
    sc.font_size = 13.0f;
    sc.command = "/usr/bin/true";
    sc.wait_after_command = true;
    sc.context = GHOSTTY_SURFACE_CONTEXT_WINDOW;

    ghostty_surface_t surface = ghostty_surface_new(app, &sc);
    if (!surface) {
      fprintf(stderr, "surface_new failed\n");
      return 5;
    }

    ghostty_surface_set_size(surface, 640, 400);
    ghostty_surface_set_content_scale(surface, 2.0, 2.0);
    ghostty_surface_set_focus(surface, true);
    ghostty_app_tick(app);
    ghostty_surface_refresh(surface);
    ghostty_surface_draw(surface);
    ghostty_app_tick(app);
    ghostty_surface_draw(surface);

    fprintf(stderr, "draw_ok surface=%p\n", surface);

    ghostty_surface_free(surface);
    ghostty_app_free(app);
    ghostty_config_free(cfg);
    fprintf(stderr, "PASS libghostty-macos draw proof\n");
    return 0;
  }
}
