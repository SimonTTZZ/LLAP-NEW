# IPA 构建指南

本项目通过 GitHub Actions 自动构建**未签名的 IPA** 文件。签名由你使用其他工具（如 [ios-app-signer](https://dantheman827.github.io/ios-app-signer/)、[TrollStore](https://github.com/opa334/TrollStore)、AltStore、Sideloadly 等）自行完成。

## 一、触发构建

将代码推送到 GitHub 仓库后，有两种方式触发构建：

1. **自动触发**：推送代码到 `main` 或 `master` 分支
2. **手动触发**：在 GitHub 仓库的 `Actions` 页面，选择 "Build IPA" 工作流，点击 "Run workflow"

## 二、下载未签名 IPA

构建完成后，在工作流运行页面的 `Artifacts` 部分下载 `llap-ipa-unsigned`，解压即可得到 `llap.ipa`。

## 三、签名 IPA

下载到的 `llap.ipa` 是未签名的，需要使用你的 Apple 开发者证书进行签名后才能安装到设备上。

### 方式 1：使用 iOS App Signer（图形界面，最简单）

1. 下载 [iOS App Signer](https://dantheman827.github.io/ios-app-signer/)
2. 打开应用，选择下载的 `llap.ipa`
3. Signing Certificate 选择你的证书
4. Provisioning Profile 选择对应的描述文件
5. 点击 Start，签名后的 IPA 会保存到指定位置

### 方式 2：使用 AltStore / Sideloadly

1. 安装 AltStore 或 Sideloadly
2. 将未签名的 IPA 拖入应用
3. 输入你的 Apple ID（需要开发者账号或免费 Apple ID）
4. 点击 Sideload 完成签名和安装

### 方式 3：使用命令行（高级）

```bash
# 解压 IPA
unzip llap.ipa -d llap_unpacked

# 签名
codesign -f -s "Apple Distribution: Your Name (TEAMID)" \
    --entitlements entitlements.plist \
    llap_unpacked/Payload/llap.app

# 重新打包
cd llap_unpacked
zip -qr ../llap-signed.ipa Payload
```

## 四、本地构建（可选）

如果你有 Mac 环境，也可以在本地构建未签名 IPA：

```bash
chmod +x build_ipa.sh
./build_ipa.sh
```

未签名的 IPA 文件将生成在 `build/ipa/llap.ipa`。

## 常见问题

**Q: 构建失败怎么办？**
A: 下载 Artifacts 中的 `build-log`，查看具体错误信息。

**Q: 未签名的 IPA 能直接安装吗？**
A: 不能。必须经过签名后才能安装到 iOS 设备。

**Q: 免费 Apple ID 能签名吗？**
A: 可以，使用 AltStore 或 Sideloadly 配合免费 Apple ID 可以签名，但每 7 天需要重新签名。
