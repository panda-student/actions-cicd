# 最小化前端项目Dockerfile配置
# 使用多阶段构建减小最终镜像体积

# === 构建阶段 ===
# 设置构建参数（可通过--build-arg覆盖）
ARG NODE_VERSION=20

# 使用Node.js Alpine镜像作为构建环境（体积小）
FROM node:${NODE_VERSION}-alpine AS builder

# 设置工作目录
WORKDIR /app

# 配置npm镜像源以加速依赖安装（国内环境优化）
RUN npm config set registry https://registry.npmmirror.com

# 先复制依赖配置文件并安装依赖
# 这样可以利用Docker层缓存，避免每次代码变更都重新安装依赖
COPY ../package*.json ./
RUN npm ci --omit=dev

# 复制项目源代码
COPY .. .

# 构建项目生成静态文件
RUN npm run build

# === 运行阶段 ===
# 使用Nginx Alpine镜像作为运行环境（体积小）
FROM nginx:alpine

# 从构建阶段复制编译后的静态文件到Nginx默认目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 设置正确的文件权限
RUN chown -R nginx:nginx /usr/share/nginx/html

# 暴露容器端口（与docker-compose.yml中的端口映射对应）
EXPOSE 80

# 启动Nginx服务（前台运行，确保容器不会退出）
CMD ["nginx", "-g", "daemon off;"]