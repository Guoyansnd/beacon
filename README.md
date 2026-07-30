# 灯塔 (Beacon)

个人自用的多协议代理客户端，支持 Android 与 Windows。

## 致谢与许可 (Attribution & License)

本项目是开源项目 **[Hiddify](https://github.com/hiddify/hiddify-app)** 的一个 fork，
遵循 **GPL-3.0 及其附加条款** 发布：<https://github.com/hiddify/hiddify-app/blob/main/LICENSE.md>

This project is a fork of **[hiddify-app](https://github.com/hiddify/hiddify-app)**,
licensed under **GPL-3.0 with additional conditions**. Full license: [LICENSE.md](LICENSE.md)

非商业用途 / NonCommercial use only.

## 本 fork 所做的修改 (Changes made in this fork)

- 品牌替换：应用名改为「灯塔 / Beacon」，替换应用图标、应用内 Logo、Windows 可执行文件名与图标、安装包信息。
- Android `applicationId` 改为 `app.beacon.client`（以便与上游版本共存）。
- 界面精简：隐藏「链式代理 / 路由 / DNS / 入站 / TLS 技巧」等高级设置入口；
  「关于」页移除上游的 Telegram 频道、条款与条件、隐私政策链接，保留源代码链接与 Hiddify 署名。
- 新增自建 GitHub Actions 构建流程（`.github/workflows/beacon-android.yml`、`beacon-windows.yml`）。

未修改任何代理内核逻辑。No changes were made to the proxy core logic.
