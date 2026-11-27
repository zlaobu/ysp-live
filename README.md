# ysp-live｜轻量级电视直播网关

[![GitHub Stars](https://img.shields.io/github/stars/tmxk2020/ysp-live?style=for-the-badge&logo=github&label=STARS)](https://github.com/tmxk2020/ysp-live/stargazers)

> 为电视、手机及 IPTV 播放器打造的统一直播入口。整合多线路资源，兼顾**启动速度、播放稳定性与画面清晰度**，让直播管理更简单。

ysp-live 是一款基于 Docker 运行的轻量级直播网关，提供统一 M3U 订阅、线路调度、按需拉流和运行诊断等能力，适用于 OpenWrt 及常见 Linux 设备。

## 核心特性

### 流畅播放体验
- **快速换台**：优化频道请求与切换流程，减少等待时间。
- **多线路切换**：支持 JCE 与 BK 双线路，线路异常时可自动切换，提升频道可用性。
- **高码率播放**：支持高码率线路，在快速启动与清晰画质之间取得平衡。
- **央视与卫视**：覆盖央视、各大卫视等多个直播频道。

### 灵活的资源调度
- **按需拉流**：根据实际播放需求获取直播流，减少不必要的上游连接。
- **并发控制**：对高码率线路进行并发管理，更合理地利用上游资源。
- **TS 缓存**：提供直播数据缓存能力，辅助改善播放连续性。

### 简单部署与管理
- **统一 M3U 订阅**：一个地址获取全频道列表，兼容常见直播播放器。
- **运行状态与诊断**：提供健康检查、频道状态及运行诊断信息，方便排查问题。
- **Docker 部署**：支持 Docker 环境及 host 网络模式，可部署于 OpenWrt 和常见 Linux 设备。

## 项目热度

通过 Star History 查看项目在 GitHub 上的 Star 增长趋势：

[![Star History Chart](https://api.star-history.com/svg?repos=tmxk2020/ysp-live&type=Date)](https://star-history.com/#tmxk2020/ysp-live&Date)

**如果您觉得项目对您有帮助，请给一个 Star 🌟，这是对我最大的鼓励！**

## 一键部署

在终端（SSH）中运行以下命令，即可通过 Docker 一键安装或更新到 GitHub 最新版本：

```sh
sh -c "$(wget -O- https://raw.githubusercontent.com/tmxk2020/ysp-live/main/install.sh)"
```

## 访问入口

| 功能 | 地址 |
|---|---|
| 全频道 M3U 订阅 | `http://设备IP:8767/all.m3u` |
| 健康检查 | `http://设备IP:8767/health` |
| 运行诊断 | `http://设备IP:8767/diag` |

将地址中的“设备IP”替换为运行 ysp-live 的设备局域网 IP。

## 更多内容请关注

- **大亨分享**：[项目主页 / 社区](https://tmxk.pp.ua)
- **Telegram 频道**：[TMXKの分享](https://t.me/tmxktg)
- **项目源码**：[GitHub - tmxk2020/ysp-live](https://github.com/tmxk2020/ysp-live)

<details>
<summary><sub>特别鸣谢</sub></summary>

<sub>感谢 Gary's Club 提供交流与支持：[Telegram 群组](https://t.me/+rgxyQeDLtjcxM2U1)</sub>

</details>

## 免责声明

本项目仅供技术学习、个人研究及合法合规的技术交流使用。项目提供的是直播网关与播放管理功能，不提供、不存储也不保证任何第三方直播内容的合法性、准确性、持续可用性或完整性。用户应自行确认所使用的直播信号及内容来源具有合法授权，并遵守所在地法律法规及相关平台服务条款。因用户自行配置、传播、使用本项目或第三方内容而产生的任何责任与风险，由用户自行承担。项目按现状提供，作者不对服务中断、线路变化、播放效果或数据损失作出保证。

