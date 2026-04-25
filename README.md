# 📺 Plasma Bigscreen Auto-Installer

Автоматическая установка [Plasma Bigscreen](https://plasma-bigscreen.org/) на **Ubuntu Server 22.04 / 24.04 LTS**.

> Plasma Bigscreen — KDE-оболочка для телевизоров и больших экранов. Управление пультом, геймпадом или клавиатурой прямо с дивана.

---

## 🚀 Быстрый старт

Ubuntu Server уже установлен? Одна команда — и готово:

```bash
curl -s https://raw.githubusercontent.com/Starchik/plasma-bigscreen-installer/main/install-bigscreen.sh | sudo bash
```

Скрипт сам всё спросит и установит. После перезагрузки система сразу загрузится в Plasma Bigscreen.

---

## ⚙️ Что делает скрипт

| Шаг | Действие | Время |
|-----|----------|-------|
| 1 | Обновление пакетов | ~1 мин |
| 2 | KDE Plasma Desktop + SDDM | ~10 мин |
| 3 | PipeWire (звук) | ~1 мин |
| 4 | Зависимости сборки | ~3 мин |
| 5 | Сборка Plasma Bigscreen из исходников | ~20–40 мин |
| 6 | Регистрация Wayland-сессии | мгновенно |
| 7 | Автологин в Bigscreen через SDDM | мгновенно |
| 8 | Flatpak + Flathub | ~1 мин |

**Итого: ~35–55 минут** в зависимости от скорости интернета и процессора.

---

## 🖥️ Требования

| Параметр | Минимум | Рекомендуется |
|----------|---------|---------------|
| ОС | Ubuntu Server 22.04 | Ubuntu Server 24.04 LTS |
| RAM | 2 ГБ | 4 ГБ+ |
| Диск | 15 ГБ свободно | 30 ГБ+ |
| Сеть | Ethernet | Ethernet |
| Дисплей | HDMI / DisplayPort | HDMI |

Протестировано на: **Fujitsu Esprimo**, обычных HTPC и мини-ПК.

---

## 📦 Что устанавливается

- **KDE Plasma Desktop** — основа рабочего окружения
- **SDDM** — менеджер входа с автологином
- **Plasma Bigscreen** — TV-интерфейс (сборка из исходников)
- **PipeWire + WirePlumber** — современная звуковая система
- **Flatpak + Flathub** — магазин приложений

---

## 🎬 Рекомендуемые приложения

После первой загрузки в Bigscreen можно установить:

```bash
# Медиацентр Kodi
sudo apt install kodi

# Jellyfin (стриминг своей медиатеки)
flatpak install flathub com.github.iwalton3.jellyfin-media-player

# YouTube
flatpak install flathub io.github.msaintfelix.VacuumTube

# Steam
sudo apt install steam
```

---

## ⚠️ Важно

- Plasma Bigscreen находится в активной разработке (pre-release) — возможны баги
- Скрипт **не трогает диск** и **не переустанавливает ОС** — работает поверх Ubuntu Server
- Если на машине уже стоял другой display manager (GDM, LightDM) — скрипт переключит на SDDM автоматически
- HDMI-CEC (управление ТВ-пультом) работает на большинстве материнских плат

---

## 🐛 Проблемы?

Открой [Issue](../../issues) с описанием ошибки, версией Ubuntu и моделью ПК.

---

## 📄 Лицензия

MIT
