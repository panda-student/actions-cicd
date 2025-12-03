# 多阶段构建减小镜像体积
# 第一阶段：构建阶段 - 使用Node.js环境构建应用
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制依赖文件（利用Docker缓存层，只有package.json变化时才重新安装依赖）
COPY package*.json ./

# 安装依赖（使用npm ci确保依赖版本锁定，比npm install更快更稳定）
RUN npm ci

# 复制源代码到容器中
COPY . .

# 构建应用（生成静态文件到dist目录）
RUN npm run build

# 第二阶段：运行阶段 - 使用轻量级的nginx服务器
FROM nginx:alpine

# 从构建阶段复制构建产物到nginx的静态文件目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 确保nginx有权限读取文件
RUN chmod -R 755 /usr/share/nginx/html

# 暴露80端口（nginx默认端口）
EXPOSE 80

# 启动nginx服务器（前台运行，保持容器运行）
CMD ["nginx", "-g", "daemon off;"]
