# tmux-hyper-linux

Linuksowy odpowiednik [tmux-hyper-mac](https://github.com/mpasternak/tmux-hyper-mac):
Caps Lock staje się klawiszem **Hyper**, a tmuxem steruje się **bezpośrednio**
(`Caps+N` nowe okno, `Caps+←/→` przełączanie okien, `Caps+H/J/K/L` panele) —
bez prefixa. Zamiast Karabinera robi to [keyd](https://github.com/rvaiya/keyd).

Kody wysyłane do terminala są **identyczne** jak w wersji macOS, więc ten sam
`~/.tmux.conf` działa na Linuksie, na Macu i na zdalnym serwerze przez SSH.

## Architektura

```
Caps + N (klawiatura fizyczna)
  │
  ▼  keyd (demon, poziom urządzenia evdev — działa w GNOME, KDE, Sway, konsoli)
     · Caps trzymane → warstwa hyper
     · Hyper+N → Shift+F1
     · Hyper+<niezmapowany klawisz> → Ctrl+Alt+Shift+Super+klawisz
  │
  ▼  Terminal (Ptyxis / GNOME Terminal / Alacritty / kitty …)
     · Shift+F1 → escape sequence `\e[1;2P`
  │
  ▼  SSH (opcjonalnie) → tmux na docelowej maszynie
  │
  ▼  tmux
     · `\e[1;2P` widzi jako `S-F1` → `bind -n S-F1 new-window`
```

keyd musi działać **lokalnie** (tam gdzie fizyczna klawiatura).

**Klawisz Windows zostaje zwykłym Superem** — GNOME dalej rozstawia nim okna
(`Win+←/→`), a `Caps+←/→` idzie do tmuxa. Nic się nie gryzie.

> Dlaczego nie `caps:hyper` z XKB? Na Linuksie Hyper z XKB domyślnie ląduje na
> tym samym modyfikatorze (Mod4) co Super, więc zachowywałby się jak Win.
> Terminal i tak nie przekazałby tmuxowi Supera. keyd robi tłumaczenie na
> poziomie urządzenia, niezależnie od środowiska graficznego.

## Wymagania

- Linux z systemd; testowane na Ubuntu 26.04 (GNOME, Wayland)
- `keyd` (Ubuntu/Debian: pakiet `keyd`, binarka nazywa się **`keyd.rvaiya`**)
- tmux ≥ 3.0
- `wl-clipboard` (copy-mode → schowek systemowy na Waylandzie)

## Instalacja

```bash
git clone https://github.com/mpasternak/tmux-hyper-linux
cd tmux-hyper-linux
./install.sh
```

Skrypt:
1. instaluje `keyd`, `tmux`, `wl-clipboard`,
2. kopiuje `keyd/default.conf` → `/etc/keyd/default.conf` (stary → backup),
   włącza i restartuje usługę `keyd`,
3. kopiuje `tmux.conf` → `~/.tmux.conf` (stary → backup) i przeładowuje tmuxa,
   jeśli działa.

Ręcznie:

```bash
sudo apt install keyd tmux wl-clipboard
sudo cp keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd && sudo keyd.rvaiya reload
cp tmux.conf ~/.tmux.conf
```

> Jeśli wcześniej ustawiałeś `caps:super` / `caps:hyper` w GNOME Tweaks —
> zdejmij to (`gsettings reset org.gnome.desktop.input-sources xkb-options`),
> żeby nie nakładało się na keyd.

## Bindy bez prefixa

**Okna i sesje**

| Skrót | Akcja | Kod |
|---|---|---|
| `Caps+N` | nowe okno (dziedziczy bieżący katalog) | `S-F1` |
| `Caps+→` | następne okno | `S-F2` |
| `Caps+←` | poprzednie okno | `S-F3` |
| `Caps+Space` | last-window (toggle) | `M-S-F6` |
| `Caps+F` | szukaj w historii panelu (copy-mode, przyrostowo) | `M-S-F7` |
| `Caps+T` | wybierz okno z listy | `C-S-F3` |
| `Caps+S` | wybierz sesję z listy | `M-S-F5` |
| `Caps+R` | rename bieżącego okna | `M-S-F1` |
| `Caps+D` | detach (wysyła `` ` d ``, nie `S-F10` — patrz Troubleshooting) | prefix + `d` |

**Panele**

| Skrót | Akcja | Kod |
|---|---|---|
| `Caps+H/J/K` | panel w lewo / dół / górę | `S-F4/F5/F6` |
| `Caps+L` | panel w prawo | `M-S-F2` |
| `Caps+↑` | nowy panel **above** | `C-S-F1` |
| `Caps+-` | nowy panel **below** | `S-F9` |
| `Caps+↓` | nowy panel **below** (jak `Caps+-`) | `S-F9` |
| `Caps+/` | nowy panel **left** | `M-S-F4` |
| `Caps+\` | nowy panel **right** | `M-S-F3` |
| `Caps+Z` | zoom panela (toggle) | `S-F11` |
| `Caps+X` | kill panel (pyta y/n) | `S-F12` |

Kolumna „Kod” to nazwa klawisza po stronie tmuxa (`M-` w tmuxie = Alt).

**Pozostałe `Caps+<klawisz>`** wysyłają `Ctrl+Alt+Shift+Super+<klawisz>` —
podepnij je pod własne skróty w GNOME (*Ustawienia → Klawiatura → Skróty
własne*) albo KDE.

## Bindy z prefixem (`` ` ``, backtick)

Jak w wersji macOS: `` ` r `` reload, `` ` [ `` copy-mode (vi: `v` selekcja,
`y` kopiuj — `wl-copy` na Linuksie, `pbcopy` na macOS), `` ` ? `` pełna lista.
Literalny backtick: `` ` `` dwa razy.

## Dodawanie własnych bindów

1. W `keyd/default.conf` w sekcji `[hyper:C-A-S-M]` dopisz
   `klawisz = <wolny kod>` — **komentarze tylko w osobnych liniach**.
   Składnia keyd: `C-` Ctrl, `A-` Alt, `S-` Shift, `M-` **Super** (nie Alt!).
2. W `tmux.conf` dopisz `bind -n <kod> <akcja>` — w tmuxie `M-` to **Alt**,
   więc keyd `A-S-f7` = tmux `M-S-F7`.
3. `sudo cp keyd/default.conf /etc/keyd/ && sudo keyd.rvaiya reload`,
   w tmuxie `` ` r ``.
4. Żeby działało też na Macu — dopisz tę samą regułę do
   `karabiner-hyper-tmux.json` w tmux-hyper-mac.

Wolne sloty: `S-F7`, `S-F8`, `C-S-F2`, `C-S-F4..F12`, `M-S-F8..F12`.
Na Linuksie nie ma ograniczeń macOS (Full Keyboard Access), ale żeby config był
wspólny, nowe bindy najlepiej dawać na kanał 3 (`Alt+Shift+Fn`).

## Troubleshooting

### `keyd: nie znaleziono polecenia`

Na Debianie/Ubuntu binarka to `keyd.rvaiya` (konflikt nazw z innym pakietem):
`sudo keyd.rvaiya monitor`, `sudo keyd.rvaiya reload`.

### Co faktycznie wychodzi z klawiatury

```bash
sudo keyd.rvaiya monitor
```

`Caps+Q` → powinno pokazać `leftcontrol leftalt leftshift leftmeta q`.
`Caps+N` → `leftshift f1`.

### Co widzi tmux

Poza tmuxem uruchom `cat -v` i wciśnij `Caps+N` → powinno być `^[[1;2P`.
Jeśli tak, a tmux nie reaguje — sprawdź `tmux list-keys -T root | grep S-F1`.

### `Caps+D` otwiera menu kontekstowe terminala

Terminale GTK traktują `Shift+F10` jako „otwórz menu”, dlatego `keyd/default.conf`
mapuje `d = macro(grave d)` — keyd wysyła po prostu prefix + `d`. Jeśli zmieniłeś
prefix, popraw `grave` w tej linii.

### Caps nadal włącza wielkie litery

`systemctl status keyd` — usługa musi być `active`. Jeśli jest, sprawdź
`sudo keyd.rvaiya monitor`, czy klawiatura w ogóle jest przechwytywana
(sekcja `[ids]` z `*` łapie wszystkie klawiatury).

### Scroll przełącza zakładki terminala (Ghostty)

Pasek zakładek GTK (AdwTabBar) przełącza zakładki kółkiem/touchpadem. Przy
scrollowaniu historii tmuxa tuż pod paskiem łatwo zmienić zakładkę. W Ghostty:
`gtk-tabs-location = hidden` (licznik zakładek + przegląd zostają w titlebarze).
Osobno: tmux domyślnie przełącza **okna** kółkiem nad status barem —
`tmux.conf` wyłącza to (`unbind -n WheelUpStatus` / `WheelDownStatus`).

### Ctrl+Shift+F w terminalu nie znajduje starszego outputu

Historia siedzi w tmuxie, nie w terminalu — szukaj przez `Caps+F` albo
prefix + `/` (copy-mode, przyrostowo; `n`/`N` następne/poprzednie).
