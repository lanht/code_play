# DanceFrame Studio

一个接入 Runway Act-Two 的网站原型：上传人物全身照和参考跳舞视频，生成“让照片人物跳同样舞蹈”的视频。

## 使用

先配置 Runway API Key：

```bash
cp .env.example .env
```

把 `.env` 里的 `RUNWAYML_API_SECRET` 换成你的 Runway API Key，然后启动本地代理服务：

```bash
npm start
```

打开：

```text
http://localhost:5173
```

## 实现说明

前端调用本地服务：

1. `POST /api/generate`：接收照片和舞蹈视频。
2. 服务端调用 Runway `/v1/uploads` 上传素材，得到 `runway://...` URI。
3. 服务端调用 Runway `/v1/character_performance`，模型为 `act_two`。
4. 前端轮询 `GET /api/jobs/:id`，服务端转发到 Runway `/v1/tasks/:id`。
5. 任务成功后，把 Runway 返回的视频 URL 渲染到结果区。

Runway 输出 URL 通常会在 24-48 小时后过期，生产环境建议下载并存入自己的对象存储。
