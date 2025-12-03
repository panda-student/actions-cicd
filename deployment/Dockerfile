# 最小化前端项目Dockerfile配置
# 使用多阶段构建减小最终镜像体积

# === 构建参数配置 ===
# 可通过--build-arg覆盖这些参数定制构建行为
ARG NODE_VERSION=20
ARG BUILD_COMMAND="npm run build"
ARG OUTPUT_DIR="dist"

# === 构建阶段 ===
FROM node:${NODE_VERSION}-alpine AS builder

# 设置工作目录
WORKDIR /app

# 配置npm镜像源以加速依赖安装（国内环境优化）
RUN npm config set registry https://registry.npmmirror.com

# 复制依赖配置文件并安装依赖
COPY package*.json ./
RUN npm ci

# 复制项目源代码
COPY . .

# 构建项目生成静态文件
RUN ${BUILD_COMMAND}

# === 运行阶段 ===
FROM nginx:alpine

# 从构建阶段复制编译后的静态文件
COPY --from=builder ${OUTPUT_DIR} /usr/share/nginx/html

# 设置正确的文件权限
RUN chown -R nginx:nginx /usr/share/nginx/html

# 暴露容器端口
EXPOSE 80

# 启动Nginx服务
CMD ["nginx", "-g", "daemon off;"]