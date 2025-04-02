#!/usr/bin/env python3
"""
背景移除工具

此脚本用于批量调用Bria服务的图片背景移除API，支持处理本地图片文件和URL图片。
提供命令行参数和交互式输入两种运行模式。

用法:
  命令行模式:
    python background_remover.py --api_token YOUR_API_TOKEN [选项]
    # 使用API Token处理单个URL图片
    python src/bria/background_remover.py --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output

    # 处理URL文本文件
    python src/bria/background_remover.py --api_token YOUR_API_TOKEN --url_file ./urls.txt --output_path ./output

    # 处理单个本地图片
    python src/bria/background_remover.py --api_token YOUR_API_TOKEN --file ./image.jpg

    # 批量处理文件夹
    python src/bria/background_remover.py --api_token YOUR_API_TOKEN --batch_folder ./images --max_workers 8 --overwrite

  交互式模式:
    python background_remover.py

  远程执行：
    必要条件：
    1. 安装Python 3.x （使用 Python 自带的 env 模块进行包管理）
    2. 安装requests库（pip install requests）
    3. 获取Bria API Token(https://platform.bria.ai/console)

    # 远程执行脚本(交互式模式, Linux/MacOS)
    python3 <(curl -s https://gitee.com/funnyzak/dotfiless/raw/main/utilities/python/bria/background_remover.py)

    # 远程执行脚本(命令行模式)
    python3 <(curl -s https://gitee.com/funnyzak/dotfiless/raw/main/utilities/python/bria/background_remover.py) --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output


选项:
  --api_token, -t      : Bria API Token
  --output_path, -o    : 输出路径(URL处理模式下必须)
  --batch_folder, -b   : 批处理文件夹路径
  --url_file, -u       : URL文本文件路径
  --overwrite, -w      : 覆盖模式
"""

import argparse
from concurrent.futures import ThreadPoolExecutor
import logging
import mimetypes
import os
from pathlib import Path
import re
import sys
import time
from typing import Any
from typing import Dict
from typing import List
from typing import Optional
from typing import Union
from urllib.parse import unquote
from urllib.parse import urlparse

import requests


# 配置日志
logging.basicConfig(
  level=logging.INFO,
  format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
  handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger("BriaBackgroundRemover")


class BriaBackgroundRemover:
  """
  Bria背景移除工具类

  用于调用Bria API移除图片背景
  """

  # API端点
  API_ENDPOINT = "https://engine.prod.bria-api.com/v1/background/remove"

  # 支持的图片格式
  SUPPORTED_FORMATS = [".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tiff"]

  def __init__(self, api_token: str, output_path: Optional[str] = None, overwrite: bool = False):
    """
    初始化背景移除工具

    Args:
      api_token: Bria API Token
      output_path: 输出路径
      overwrite: 是否覆盖已存在的文件
    """
    self.api_token = api_token
    self.output_path = output_path
    self.overwrite = overwrite

    # 创建输出目录(如果指定且不存在)
    if self.output_path and not os.path.exists(self.output_path):
      os.makedirs(self.output_path, exist_ok=True)

  def get_content_type(self, file_path: str) -> str:
    """
    获取文件的MIME类型

    Args:
      file_path: 文件路径

    Returns:
      文件的MIME类型
    """
    # 使用mimetypes模块获取文件类型
    content_type, _ = mimetypes.guess_type(file_path)
    if not content_type:
      # 如果无法确定，默认使用通用的图片类型
      content_type = "application/octet-stream"
    return content_type

  def _get_output_filename(self, orig_path: str) -> str:
    """
    生成输出文件名

    Args:
      orig_path: 原始文件路径或URL

    Returns:
      处理后的输出文件名
    """
    # 判断是否为URL
    if orig_path.startswith(("http://", "https://")):
      # 从URL中提取文件名
      parsed_url = urlparse(orig_path)
      file_name = os.path.basename(unquote(parsed_url.path))

      # 如果URL没有有效的文件名，使用URL的哈希值
      if not file_name or "." not in file_name:
        file_name = f"url_image_{hash(orig_path) % 10000}.jpg"
    else:
      # 本地文件，直接获取文件名
      file_name = os.path.basename(orig_path)

    # 添加_rmbg后缀
    name, ext = os.path.splitext(file_name)
    return f"{name}_rmbg.png"

  def remove_background_by_url(self, image_url: str) -> Optional[str]:
    """
    通过URL移除图片背景

    Args:
      image_url: 图片URL

    Returns:
      处理后图片的URL，处理失败则返回None
    """
    try:
      # 准备请求头和参数
      headers = {"api_token": self.api_token, "Content-Type": "application/x-www-form-urlencoded"}
      data = {"image_url": image_url}

      # 发送API请求
      response = requests.post(self.API_ENDPOINT, headers=headers, data=data)

      # 检查响应状态
      if response.status_code == 200:
        result = response.json()
        if "result_url" in result:
          return result["result_url"]
        else:
          logger.error(f"API返回的响应中没有result_url字段: {result}")
      else:
        logger.error(f"API调用失败，状态码: {response.status_code}, 响应: {response.text}")

    except Exception as e:
      logger.error(f"处理URL图片时出错: {image_url}, 错误: {str(e)}")

    return None

  def remove_background_by_file(self, file_path: str) -> Optional[str]:
    """
    通过文件移除图片背景

    Args:
      file_path: 图片文件路径

    Returns:
      处理后图片的URL，处理失败则返回None
    """
    try:
      # 检查文件是否存在
      if not os.path.isfile(file_path):
        logger.error(f"文件不存在: {file_path}")
        return None

      # 获取文件MIME类型
      content_type = self.get_content_type(file_path)

      # 准备请求头和文件
      headers = {"api_token": self.api_token}

      with open(file_path, "rb") as f:
        files = {"file": (os.path.basename(file_path), f, content_type)}

        # 发送API请求
        response = requests.post(self.API_ENDPOINT, headers=headers, files=files)

        # 检查响应状态
        if response.status_code == 200:
          result = response.json()
          if "result_url" in result:
            return result["result_url"]
          else:
            logger.error(f"API返回的响应中没有result_url字段: {result}")
        else:
          logger.error(f"API调用失败，状态码: {response.status_code}, 响应: {response.text}")

    except Exception as e:
      logger.error(f"处理本地文件时出错: {file_path}, 错误: {str(e)}")

    return None

  def download_image(self, url: str, output_path: str) -> bool:
    """
    下载图片并保存到指定路径

    Args:
      url: 图片URL
      output_path: 保存路径

    Returns:
      是否成功下载并保存
    """
    try:
      # 检查输出路径是否已存在
      if os.path.exists(output_path) and not self.overwrite:
        logger.info(f"跳过已存在的文件: {output_path}")
        return False

      # 下载图片
      response = requests.get(url, stream=True)
      if response.status_code == 200:
        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # 保存图片
        with open(output_path, "wb") as f:
          for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

        logger.info(f"已保存处理后的图片: {output_path}")
        return True
      else:
        logger.error(f"下载图片失败，状态码: {response.status_code}, URL: {url}")

    except Exception as e:
      logger.error(f"下载图片时出错: {url}, 错误: {str(e)}")

    return False

  def process_single_url(self, url: str) -> bool:
    """
    处理单个URL图片

    Args:
      url: 图片URL

    Returns:
      是否成功处理
    """
    logger.info(f"正在处理URL图片: {url}")

    # 检查输出路径是否设置
    if not self.output_path:
      logger.error("处理URL图片时必须设置输出路径")
      return False

    # 调用API移除背景
    result_url = self.remove_background_by_url(url)
    if not result_url:
      return False

    # 生成输出文件名
    output_filename = self._get_output_filename(url)
    output_path = os.path.join(self.output_path, output_filename)

    # 下载处理后的图片
    return self.download_image(result_url, output_path)

  def process_url_file(self, url_file_path: str) -> Dict[str, int]:
    """
    处理URL文本文件

    Args:
      url_file_path: URL文本文件路径

    Returns:
      处理统计结果
    """
    stats = {"total": 0, "success": 0, "failed": 0}

    # 检查文件是否存在
    if not os.path.isfile(url_file_path):
      logger.error(f"URL文件不存在: {url_file_path}")
      return stats

    logger.info(f"正在处理URL文件: {url_file_path}")

    # 读取URL文件
    urls = []
    try:
      with open(url_file_path, "r") as f:
        urls = [line.strip() for line in f if line.strip()]
    except Exception as e:
      logger.error(f"读取URL文件时出错: {url_file_path}, 错误: {str(e)}")
      return stats

    stats["total"] = len(urls)
    logger.info(f"找到 {stats['total']} 个URL需要处理")

    # 处理每个URL
    for i, url in enumerate(urls, 1):
      logger.info(f"[{i}/{stats['total']}] 处理URL: {url}")
      success = self.process_single_url(url)
      if success:
        stats["success"] += 1
      else:
        stats["failed"] += 1

    logger.info(f"URL文件处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")
    return stats

  def process_single_file(self, file_path: str, custom_output_path: Optional[str] = None) -> bool:
    """
    处理单个图片文件

    Args:
      file_path: 图片文件路径
      custom_output_path: 自定义输出路径

    Returns:
      是否成功处理
    """
    logger.info(f"正在处理图片文件: {file_path}")

    # 调用API移除背景
    result_url = self.remove_background_by_file(file_path)
    if not result_url:
      return False

    # 生成输出文件名
    output_filename = self._get_output_filename(file_path)

    if custom_output_path:
      # 使用自定义输出路径
      output_path = os.path.join(custom_output_path, output_filename)
    else:
      # 使用原图所在目录
      output_path = os.path.join(os.path.dirname(file_path), output_filename)

    # 下载处理后的图片
    return self.download_image(result_url, output_path)

  def process_folder(self, folder_path: str, max_workers: int = 4) -> Dict[str, int]:
    """
    处理文件夹中的所有图片

    Args:
      folder_path: 文件夹路径
      max_workers: 最大并发工作线程数

    Returns:
      处理统计结果
    """
    stats = {"total": 0, "success": 0, "failed": 0}

    # 检查文件夹是否存在
    if not os.path.isdir(folder_path):
      logger.error(f"文件夹不存在: {folder_path}")
      return stats

    logger.info(f"正在处理文件夹: {folder_path}")

    # 收集所有支持的图片文件
    image_files = []
    for root, _, files in os.walk(folder_path):
      for file in files:
        if any(file.lower().endswith(ext) for ext in self.SUPPORTED_FORMATS):
          image_files.append(os.path.join(root, file))

    stats["total"] = len(image_files)
    logger.info(f"找到 {stats['total']} 个图片文件需要处理")

    success_count = 0
    failed_count = 0

    # 单线程处理
    if max_workers <= 1:
      for i, file_path in enumerate(image_files, 1):
        logger.info(f"[{i}/{stats['total']}, Success: {success_count}, Failed: {failed_count}] 处理文件: {file_path}")
        success = self.process_single_file(file_path)
        if success:
          success_count += 1
        else:
          failed_count += 1
    else:
      # 并发处理
      logger.info(f"使用 {max_workers} 个线程并发处理")

      def process_file_wrapper(file_path):
        nonlocal success_count, failed_count
        index = image_files.index(file_path) + 1
        logger.info(f"[{index}/{stats['total']}, Success: {success_count}, Failed: {failed_count}] 处理文件: {file_path}")
        success = self.process_single_file(file_path)
        if success:
          success_count += 1
          return True
        else:
          failed_count += 1
          return False

      with ThreadPoolExecutor(max_workers=max_workers) as executor:
        results = list(executor.map(process_file_wrapper, image_files))
        success_count = sum(1 for r in results if r)
        failed_count = stats["total"] - success_count

    stats["success"] = success_count
    stats["failed"] = failed_count
    logger.info(f"文件夹处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")
    return stats


def interactive_mode() -> None:
  """交互式模式"""
  print("=" * 50)
  print("Bria 背景移除工具 - 交互式模式")
  print("=" * 50)

  # 获取API Token
  api_token = input("请输入Bria API Token: ").strip()
  if not api_token:
    print("错误: API Token不能为空")
    return

  # 选择处理模式
  print("\n请选择处理模式:")
  print("1. 处理单个URL")
  print("2. 处理URL文件")
  print("3. 处理单个图片文件")
  print("4. 处理图片文件夹")

  choice = input("\n请输入选择 (1-4): ").strip()

  # 是否覆盖已存在的文件
  overwrite_input = input("是否覆盖已存在的文件? (y/n, 默认n): ").strip().lower()
  overwrite = overwrite_input == "y"

  if choice == "1":
    # 单个URL模式
    url = input("请输入图片URL: ").strip()
    if not url:
      print("错误: URL不能为空")
      return

    output_path = input("请输入输出路径: ").strip()
    if not output_path:
      print("错误: 输出路径不能为空")
      return

    remover = BriaBackgroundRemover(api_token, output_path, overwrite)
    result = remover.process_single_url(url)

    if result:
      print("✅ 处理成功!")
    else:
      print("❌ 处理失败")

  elif choice == "2":
    # URL文件模式
    url_file = input("请输入URL文件路径: ").strip()
    if not os.path.isfile(url_file):
      print(f"错误: URL文件不存在: {url_file}")
      return

    output_path = input("请输入输出路径: ").strip()
    if not output_path:
      print("错误: 输出路径不能为空")
      return

    remover = BriaBackgroundRemover(api_token, output_path, overwrite)
    stats = remover.process_url_file(url_file)

    print(f"\n处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")

  elif choice == "3":
    # 单个文件模式
    file_path = input("请输入图片文件路径: ").strip()
    if not os.path.isfile(file_path):
      print(f"错误: 文件不存在: {file_path}")
      return

    output_dir_input = input("请输入输出目录 (留空则使用源文件目录): ").strip()
    output_dir = output_dir_input if output_dir_input else None

    remover = BriaBackgroundRemover(api_token, output_dir, overwrite)
    result = remover.process_single_file(file_path, output_dir)

    if result:
      print("✅ 处理成功!")
    else:
      print("❌ 处理失败")

  elif choice == "4":
    # 文件夹模式
    folder_path = input("请输入图片文件夹路径: ").strip()
    if not os.path.isdir(folder_path):
      print(f"错误: 文件夹不存在: {folder_path}")
      return

    max_workers_input = input("请输入最大并发线程数 (默认为4): ").strip()
    try:
      max_workers = int(max_workers_input) if max_workers_input else 4
    except ValueError:
      max_workers = 4
      print("警告: 无效的线程数，使用默认值4")

    remover = BriaBackgroundRemover(api_token, None, overwrite)
    stats = remover.process_folder(folder_path, max_workers)

    print(f"\n处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")

  else:
    print("错误: 无效的选择")


def main():
  """主函数，解析命令行参数并执行相应操作"""
  # 定义命令行参数
  parser = argparse.ArgumentParser(description="Bria背景移除工具 - 批量移除图片背景")
  parser.add_argument("--api_token", "-t", help="Bria API Token")
  parser.add_argument("--output_path", "-o", help="输出路径")
  parser.add_argument("--batch_folder", "-b", help="批处理文件夹路径")
  parser.add_argument("--url_file", "-u", help="URL文本文件路径")
  parser.add_argument("--overwrite", "-w", action="store_true", help="覆盖模式，如果设置则覆盖已存在的文件")
  parser.add_argument("--max_workers", "-m", type=int, default=4, help="最大并发工作线程数 (默认: 4)")
  parser.add_argument("--url", help="单个URL处理")
  parser.add_argument("--file", "-f", help="单个文件处理")

  args = parser.parse_args()

  # 如果没有提供任何参数，进入交互式模式
  if len(sys.argv) == 1:
    interactive_mode()
    return

  # 检查必要参数
  if not args.api_token:
    print("错误: 必须提供API Token (--api_token 或 -t)")
    return

  # 检查处理模式是否是URL或URL文件，但没有提供输出路径
  if (args.url or args.url_file) and not args.output_path:
    print("错误: 处理URL或URL文件时必须提供输出路径 (--output_path 或 -o)")
    return

  # 创建背景移除工具实例
  remover = BriaBackgroundRemover(args.api_token, args.output_path, args.overwrite)

  # 根据参数执行相应操作
  if args.batch_folder:
    # 批处理文件夹模式
    if not os.path.isdir(args.batch_folder):
      print(f"错误: 文件夹不存在: {args.batch_folder}")
      return

    stats = remover.process_folder(args.batch_folder, args.max_workers)
    print(f"\n处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")

  elif args.url_file:
    # URL文件模式
    if not os.path.isfile(args.url_file):
      print(f"错误: URL文件不存在: {args.url_file}")
      return

    stats = remover.process_url_file(args.url_file)
    print(f"\n处理完成: 总计 {stats['total']}, 成功 {stats['success']}, 失败 {stats['failed']}")

  elif args.url:
    # 单个URL模式
    result = remover.process_single_url(args.url)
    if result:
      print("✅ 处理成功!")
    else:
      print("❌ 处理失败")

  elif args.file:
    # 单个文件模式
    if not os.path.isfile(args.file):
      print(f"错误: 文件不存在: {args.file}")
      return

    result = remover.process_single_file(args.file)
    if result:
      print("✅ 处理成功!")
    else:
      print("❌ 处理失败")

  else:
    parser.print_help()


if __name__ == "__main__":
  main()
