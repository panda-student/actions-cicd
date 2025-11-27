# 构建阶段：使用Node.js镜像编译Vue项目
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制依赖配置文件
COPY package*.json ./

# 安装项目依赖
RUN npm install

# 复制项目源代码
COPY . .

# 构建项目生成静态文件
RUN npm run build

# 运行阶段：使用Nginx提供静态资源服务
FROM nginx:alpine

# 从构建阶段复制编译后的静态文件到Nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# 暴露容器端口
EXPOSE 80

# 启动Nginx服务
CMD ["nginx", "-g", "daemon off;"]