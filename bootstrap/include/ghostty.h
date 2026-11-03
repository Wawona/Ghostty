#pragma once
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int ghostty_init(void);
void ghostty_shutdown(void);
typedef struct GhosttySurface GhosttySurface;
GhosttySurface *ghostty_surface_new(void *opts);
void ghostty_surface_free(GhosttySurface *s);
void ghostty_surface_write(GhosttySurface *s, const char *bytes, size_t len);
void ghostty_surface_key(GhosttySurface *s, uint32_t keycode, uint32_t mods, int down);
void ghostty_surface_resize(GhosttySurface *s, uint32_t cols, uint32_t rows, uint32_t px_w, uint32_t px_h);
void *ghostty_surface_layer(GhosttySurface *s);
#ifdef __cplusplus
}
#endif
