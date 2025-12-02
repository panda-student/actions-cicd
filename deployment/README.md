# 通用Docker部署架构

## 架构概述

本架构将部署流程固化为通用模板，支持前端、C#后端、Python后端等多种技术栈的统一部署。

### 核心设计原则

1. **固化流程**：部署流程统一，通过通用模板实现
2. **变化分离**：项目特定配置由各仓库自行维护
3. **技术栈无关**：支持多种技术栈的统一部署
4. **环境隔离**：生产/测试环境完全分离

## 目录结构

```
deployment/
├── .env.prod                     # 生产环境配置（支持多项目类型）
├── .env.test                     # 测试环境配置（支持多项目类型）
├── Dockerfile                    # 最小化前端Dockerfile配置（支持参数化构建）
├── docker-compose.yml            # 通用Docker Compose配置模板
└── README.md                     # 部署说明文档

examples/                         # 示例配置
├── csharp-backend/               # C#后端项目示例
└── python-backend/               # Python后端项目示例
```

## 使用方式

### 通用部署命令

所有项目类型使用相同的部署命令，通过环境变量文件适配不同配置：

```bash
# 生产环境部署
cd deployment
docker-compose --env-file .env.prod up -d

# 测试环境部署
docker-compose --env-file .env.test up -d

# 查看服务状态
docker-compose --env-file .env.prod ps

# 停止服务
docker-compose --env-file .env.prod down

# 查看日志
docker-compose --env-file .env.prod logs -f
```

### 项目类型适配

部署架构自动根据 `PROJECT_TYPE` 环境变量适配不同项目类型：

- **前端项目** (`PROJECT_TYPE=frontend`): 使用Nginx运行静态文件
- **C#后端项目** (`PROJECT_TYPE=csharp`): 使用.NET运行时环境
- **Python后端项目** (`PROJECT_TYPE=python`): 使用Python运行时环境

### 快速开始

1. **配置环境变量**: 根据项目类型修改 `.env.prod` 和 `.env.test` 文件
2. **构建镜像**: 使用项目特定的Dockerfile构建镜像
3. **启动服务**: 使用docker-compose命令启动服务
4. **验证部署**: 访问服务端口验证部署成功

## 项目维护示例

### 前端项目维护示例

**环境变量配置** (.env.prod / .env.test):
```bash
# 基础配置
ENVIRONMENT=prod
PROJECT_TYPE=frontend

# Docker镜像配置
IMAGE_NAME=your-frontend-app
IMAGE_TAG=${ENVIRONMENT}

# 服务配置
SERVICE_PREFIX=frontend-prod
PORT_MAPPING=80:80

# 健康检查配置
HEALTHCHECK_COMMAND=["CMD", "curl", "-f", "http://localhost"]

# 运行时环境变量
NODE_ENV=production
```

**Dockerfile自定义构建参数**:
```dockerfile
# 使用自定义构建参数
ARG NODE_VERSION=18
ARG BUILD_COMMAND="npm run build:prod"
ARG OUTPUT_DIR="/app/dist"

# 构建阶段使用自定义参数
FROM node:${NODE_VERSION}-alpine AS builder
# ... 构建逻辑保持不变
```

**构建命令示例**:
```bash
# 使用默认参数构建
docker build -t your-frontend-app:prod .

# 使用自定义参数构建
docker build \
  --build-arg NODE_VERSION=18 \
  --build-arg BUILD_COMMAND="npm run build:prod" \
  -t your-frontend-app:prod .
```

### C#后端项目维护示例

**环境变量配置** (.env.prod):
```bash
# 基础配置
ENVIRONMENT=prod
PROJECT_TYPE=csharp

# Docker镜像配置
IMAGE_NAME=your-csharp-api
IMAGE_TAG=${ENVIRONMENT}

# 服务配置
SERVICE_PREFIX=api-prod
PORT_MAPPING=8080:80

# 健康检查配置
HEALTHCHECK_COMMAND=["CMD", "curl", "-f", "http://localhost/health"]

# 运行时环境变量
NODE_ENV=production
ASPNETCORE_ENVIRONMENT=Production
```

**项目特定Dockerfile示例**:
```dockerfile
# 基于通用模板的C#项目Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# 复制项目文件
COPY YourApp.csproj .
RUN dotnet restore

# 复制源代码并构建
COPY . .
RUN dotnet publish -c Release -o /app/publish

# 运行阶段
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

# 设置非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 启动应用
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

### Python后端项目维护示例

**环境变量配置** (.env.test):
```bash
# 基础配置
ENVIRONMENT=test
PROJECT_TYPE=python

# Docker镜像配置
IMAGE_NAME=your-python-api
IMAGE_TAG=${ENVIRONMENT}

# 服务配置
SERVICE_PREFIX=api-test
PORT_MAPPING=8000:8000

# 健康检查配置
HEALTHCHECK_COMMAND=["CMD", "curl", "-f", "http://localhost:8000/health"]

# 运行时环境变量
NODE_ENV=development
PYTHON_ENV=development
```

**项目特定Dockerfile示例**:
```dockerfile
# 基于通用模板的Python项目Dockerfile
FROM python:3.11-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y gcc

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 运行阶段
FROM python:3.11-slim
WORKDIR /app

# 复制已安装的包
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# 复制应用代码
COPY . .

# 设置非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 启动应用
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

## 配置说明

### Docker Compose配置 (docker-compose.yml)

通用Docker Compose模板支持以下特性：

- **多项目类型支持**：通过环境变量自动适配前端、C#、Python项目
- **健康检查**：内置容器健康检查机制，确保服务可用性
- **日志管理**：JSON格式日志，限制日志文件大小
- **自动重启**：容器异常退出时自动重启

### 环境变量配置

环境变量文件支持以下配置项：

- **基础配置**
  - `ENVIRONMENT`：环境类型 (prod/test)
  - `PROJECT_TYPE`：项目类型 (frontend/csharp/python)

- **Docker镜像配置**
  - `IMAGE_NAME`：Docker镜像名称
  - `IMAGE_TAG`：镜像标签

- **服务配置**
  - `SERVICE_PREFIX`：服务名称前缀
  - `PORT_MAPPING`：端口映射 (主机端口:容器端口)
  - `HEALTHCHECK_COMMAND`：健康检查命令

- **运行时环境变量**
  - `NODE_ENV`：Node.js环境变量
  - `ASPNETCORE_ENVIRONMENT`：.NET Core环境变量
  - `PYTHON_ENV`：Python环境变量

### Dockerfile配置

当前Dockerfile针对前端项目优化，支持以下特性：

- **多阶段构建**：减小最终镜像体积
- **参数化构建**：支持自定义Node版本、构建命令、输出目录
- **层缓存优化**：优先复制package.json，利用Docker缓存
- **国内镜像源**：配置npm镜像源加速依赖安装

## 优势

1. **配置最小化**：部署目录仅包含5个核心文件，结构清晰简洁
2. **多项目支持**：一套配置支持前端、C#、Python三种主流项目类型
3. **环境隔离**：生产/测试环境通过环境变量文件完全隔离
4. **标准化流程**：统一的Docker Compose部署流程
5. **运维自动化**：内置健康检查、日志管理、自动重启等运维功能
6. **参数化构建**：Dockerfile支持参数化配置，灵活适配不同项目需求

## 扩展新项目类型

如需支持新的项目类型，参考以下步骤：

1. **环境变量配置**：在 `.env.prod` 和 `.env.test` 文件中添加新项目类型的配置
2. **Dockerfile创建**：为新项目类型创建专用的Dockerfile构建逻辑
3. **服务适配**：确保docker-compose.yml能够正确识别和处理新项目类型
4. **测试验证**：创建示例项目验证新类型的部署流程
5. **文档更新**：在README.md中添加新类型的部署和维护说明

### 示例：添加Java后端项目支持

```bash
# 1. 更新环境变量文件
PROJECT_TYPE=java
IMAGE_NAME=my-java-app

# 2. 创建Java专用的Dockerfile
FROM openjdk:17-jdk-slim
# ... Java项目构建逻辑

# 3. 更新docker-compose.yml中的服务配置
# (当前架构已支持通过环境变量自动适配)
```