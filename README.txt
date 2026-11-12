========================================================
 MpcVR Plus
 MPC Video Renderer 增强包 —— 补帧 / 超分 / HDR
 版本 1.14   打包日期 2026-11-12
 渲染器内核：MPC Video Renderer 0.11.2.51（已汉化）
 构建标识 BuildId：8c1fe763e2ee5a59
========================================================

【这是什么】
  这是一个基于 MPC Video Renderer（简称 MPCVR）改造的 DirectShow 视频渲染器，
  在保留原版全部能力的基础上，增加了「补帧」「超分」两类 AI 画质功能，
  并且已经把全部需要的运行库一起打包进本文件夹。

  安装它，PotPlayer 就能把 24/30fps 的老片源插帧到 60~240fps，
  也能把低分辨率片源用显卡 AI 放大到高清。

【三步安装】
  1. 把整个 MpcVR-Plus 文件夹解压到任意位置（建议路径不要含中文和空格）
  2. 右键 install.cmd  →  选择「以管理员身份运行」
  3. 打开 PotPlayer 播放视频，在画面上点右键 →「滤镜」→「MPC Video Renderer」
     即可打开设置页

  详细的安装步骤和排错见【安装说明.txt】，
  每个功能具体怎么开、怎么调见【使用教程.txt】。

【这个包比原版 MPCVR 多了什么】
  1) 补帧（帧生成）—— 把视频帧率翻倍到 2X~8X
     共 5 种后端，在属性页「补帧方式」里选择：
        · NVIDIA DLSS 帧生成      倍率 2X~6X   （需 RTX 40 系 / 50 系）
        · NVIDIA VFG 帧生成       倍率 2X~8X   （需 RTX 40 系 / 50 系）
        · AMD FSR 3.1            倍率 2X      （NVIDIA / AMD / Intel 显卡都能用）
        · Intel XeSS             倍率 2X~4X   （NVIDIA / AMD 也能用，上限通常更低）
        · AMD FSR 4 ML 帧生成     倍率 2X      （未验收，默认不建议使用）
  2) 超分（AI 放大）—— 在属性页「超分算法」里选择
        · AMD FSR 3.1            跨显卡可用
        · NVIDIA DLSS SR         需 RTX 20 系及以上
  3) HDR
        HDR10 / Dolby Vision 直通、RTX 视频 HDR（由显卡驱动实现）
  4) 原版 MPCVR 的全部能力
        缩放算法（最近邻 / 双线性 / Catmull-Rom / Lanczos2/3 / Jinc2m 等）、
        RTX 视频超分（属性页「请求超分」）、字幕与 OSD 合成、
        统计信息显示、DXVA2 与 D3D11 视频处理器、反交错、抖动等

【系统与硬件要求】
  操作系统  Windows 10 1809 或更高 / Windows 11（仅 64 位）
  播放器    PotPlayer 64 位（也支持 MPC-BE / MPC-HC，
            把视频渲染器选成 "MPC Video Renderer" 即可）
  显卡      任意支持 DirectX 12 的显卡都能用基础功能、FSR、XeSS；
            NVIDIA 专属功能另有要求：
              · DLSS 帧生成   RTX 40 系 / 50 系
              · NVIDIA VFG    RTX 40 系 / 50 系（Ada / Blackwell 架构）
              · DLSS 超分     RTX 20 系及以上
  驱动      建议安装较新的显卡驱动。插帧需要的光流库 nvofapi64.dll 由显卡驱动
            自带（装在 C:\Windows\System32），包内不含、也无需额外安装。
  建议      在「设置 → 系统 → 显示 → 图形 → 默认图形设置」里开启
            「硬件加速 GPU 计划 (HAGS)」，插帧会更稳定。

【包内文件说明】
  MpcVideoRenderer64.ax            渲染器本体（安装时由 regsvr32 注册）
  MpcVideoRenderer64.ax.manifest   清单文件，必须与 ax 放在同一目录
  shaders\                         渲染器用到的着色器（25 个 .dxil），必须与 ax 同级
  ngx\                             NVIDIA NGX 运行库：DLSS 帧生成 + DLSS 超分
  amd\fidelityfx\                  AMD FidelityFX 运行库：FSR 3.1 / FSR 4 ML
  intel\experimental\              Intel XeSS 运行库
  nvidia-vfg\                      NVIDIA VFG 运行库（含 CUDA 运行库）
  install.cmd                      安装脚本（需要管理员权限）
  uninstall.cmd                    卸载脚本（需要管理员权限）
  settings.reg                     渲染器默认设置，首次安装时自动导入
  README.txt                       本文件
  安装说明.txt                      完整的安装 / 卸载 / 回退 / 安装排错
  使用教程.txt                      每个功能怎么开、怎么调、怎么排错

  关于运行库目录里额外带的三个文件：
  ngx / amd\fidelityfx / intel\experimental / nvidia-vfg 每个目录里都带了一份
  MSVCP140.dll、VCRUNTIME140.dll、VCRUNTIME140_1.dll。
  这些是 Visual C++ 运行库，FSR / XeSS / VFG 的 DLL 需要它们才能加载。
  带上它们是为了让本包在「没有安装 Visual C++ 运行库」的电脑上也能直接用。

【安装后文件放在哪里】
  安装目录：%LOCALAPPDATA%\MpcVR-DLSS\
      MpcVideoRenderer64.ax       ← 真正被注册、被播放器加载的渲染器
      MpcVideoRenderer64.ax.manifest
      shaders\   ngx\   amd\   intel\   nvidia-vfg\
      logs\fg.log                 ← 运行日志，排查问题时看这里

  对 PotPlayer 的改动（只动这两个值）：
      HKCU\Software\DAUM\PotPlayerMini64\Settings
          VideoRen2  = 16     把视频渲染器指向本渲染器
          SkinUseOsc = 0
  渲染器自身的设置保存在：
      HKCU\Software\MPC-BE Filters\MPC Video Renderer

【为什么包里只放这些运行库（体积已优化）】
  · 显卡驱动已经自带、不需要放进包里的：
      nvofapi64.dll         光流库，装显卡驱动时已放进 C:\Windows\System32
      _nvngx.dll 与 NGX 模型文件   驱动自带（DriverStore、ProgramData\NVIDIA）
  · 经过实测确认「本插件根本不会加载」，所以没有放进包里的：
      nvngx_vsr.dll      约 19 MB   本渲染器的「请求超分（RTX 视频超分）」走的是
                                    D3D11 视频处理器扩展，由显卡驱动实现，
                                    不经过 NGX
      nvngx_truehdr.dll  约 4 MB    同上，「RTX 视频 HDR」也不经过 NGX
      nvngx_dlssnr.dll 及降噪模型  约 500 MB   本插件没有视频降噪功能
  · 补帧与超分真正会用到的运行库已经全部放进包内，
    装完即可用，正常情况下不需要再补任何文件。

【许可与来源】
  · 渲染器基于 MPC Video Renderer 改造（GPL-3.0），修改部分同样遵循 GPL-3.0。
    上游源码：https://github.com/clsid2/MPCVideoRenderer
   · 包内的 NVIDIA NGX / NVIDIA Video Effects、AMD FidelityFX、Intel XeSS、
    Microsoft Visual C++ 运行库等第三方组件，版权归各自所有者，
    按各自许可随包分发，仅供本机自用，请勿公开再分发。
  · 本包为个人自用增强包，不是官方发布版本，不提供任何担保。
========================================================
