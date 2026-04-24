# 📺 Plasma Bigscreen Auto-Installer

Автоматическая установка [Plasma Bigscreen](https://plasma-bigscreen.org/) на базе **Arch Linux** для x86/x64 ПК (Fujitsu Esprimo, HTPC, мини-ПК и др.).

> Plasma Bigscreen — KDE-оболочка для телевизоров. Управление пультом, геймпадом или клавиатурой с дивана.

---

## 🚀 Быстрый старт

1. Скачай и запиши [Arch Linux ISO](https://archlinux.org/download/) на флешку (через [Rufus](https://rufus.ie/) в режиме DD или [Etcher](https://etcher.balena.io/))
2. Загрузись с флешки на своём ПК
3. Выполни в консоли:

```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/plasma-bigscreen-installer/main/install-bigscreen.sh
bash install-bigscreen.sh
```

Скрипт сам спросит нужные данные и всё установит.

---

## ⚙️ Что делает скрипт

### Этап 1 (с Live USB, ~10–15 мин)
- Размечает диск (EFI + Linux разделы)
- Устанавливает Arch Linux
- Устанавливает KDE Plasma, SDDM, PipeWire
- Настраивает локаль, hostname, пользователя
- Устанавливает загрузчик GRUB
- Подготавливает скрипт второго этапа

### Этап 2 (после первой загрузки, ~20–25 мин)
- Устанавливает `yay` (AUR helper)
- Устанавливает `plasma-bigscreen-git` из AUR
- Подключает Flathub
- Настраивает автологин в Bigscreen

---

## 🖥️ Требования

| Параметр | Минимум |
|---|---|
| Архитектура | x86_64 |
| RAM | 2 ГБ (рекомендуется 4 ГБ+) |
| Диск | 20 ГБ+ |
| Загрузка | UEFI |
| Сеть | Ethernet (кабель) во время установки |

Протестировано на: **Fujitsu Esprimo**, обычных HTPC и мини-ПК.

---

## 📦 Устанавливаемый софт

- **Arch Linux** — основа системы
- **KDE Plasma** + **SDDM** — рабочее окружение
- **Plasma Bigscreen** — TV-интерфейс
- **PipeWire** — звук
- **Flatpak** + **Flathub** — магазин приложений

### После установки можно добавить:
```bash
sudo pacman -S kodi          # Медиацентр
sudo pacman -S steam         # Steam
flatpak install io.github.msaintfelix.VacuumTube  # YouTube
flatpak install com.github.iwalton3.jellyfin-media-player  # Jellyfin
```

---

## ⚠️ Предупреждения

- **Скрипт полностью сотрёт выбранный диск.** Перед запуском убедись, что выбрал правильный диск.
- Plasma Bigscreen пока в стадии активной разработки (pre-release), возможны баги.
- HDMI-CEC (управление ТВ-пультом) работает на большинстве материнских плат, но не на всех.

---

## 🐛 Проблемы?

Открой [Issue](../../issues) с описанием проблемы и моделью ПК.

---

## 📄 Лицензия

MIT
