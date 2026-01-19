# Node.js Utilities

This directory contains Node.js utility scripts to enhance your workflow.

## Contents
- [JSON to Files Generator](#json-to-files-generator)
- [Swagger API Path Filter](#swagger-api-path-filter)

## JSON to Files Generator

`json-to-files.js` is a versatile Node.js script designed to extract data from JSON files and generate corresponding files. It can iterate through arrays in JSON, create individual files for each item, and optionally download media resources from HTML content.

### Features
- **Flexible JSON Extraction**: Process items from customizable array properties
- **Customizable File Naming**: Create files using specified properties for names
- **Media Resource Downloading**: Automatically download images, videos, and audio files referenced in HTML content
- **URL Replacement**: Replace remote URLs with local paths in generated content
- **Post-Processing**: Execute custom commands on each generated file
- **Parallel Processing**: Option for concurrent command execution
- **Batch Processing**: Process multiple JSON files in a single run

### Requirements
- Node.js 10.x or higher

### Usage

#### Basic Usage
Process JSON files with default options:

```bash
# Process a single JSON file
node json-to-files.js data.json

# Process multiple JSON files
node json-to-files.js data1.json data2.json
```

#### Customization Options
Specify output directory and file format:

```bash
# Output to specific directory with custom extension
node json-to-files.js data.json -o ./output --fileExtension md

# Customize JSON property extraction
node json-to-files.js custom.json --listProp articles --fileName custom_title --content body
```

#### Media Resource Processing
Download and manage media resources:

```bash
# Enable media resource downloading
node json-to-files.js data.json -d

# Custom resource directory and naming
node json-to-files.js data.json -d --assetsDir media --assetsPrefix img_

# Control URL replacement and unique naming
node json-to-files.js data.json -d --replaceUrls true --uniqueAssetName false
```

#### Post-Processing
Execute commands on generated files:

```bash
# Convert HTML to Markdown
node json-to-files.js data.json -e "html-to-md {filepath} > {dir}/{file}.md"

# Run commands in parallel
node json-to-files.js data.json -e "process-file {filepath}" --execParallel
```

#### Remote Execution
Execute the script directly without downloading:

```bash
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/nodejs/json-to-files.js | npx -y node - json1.json [options]
```

### Command-Line Options
- **`-o, --output <dir>`**: Output directory path (default: current directory)
- **`--listProp <prop>`**: JSON property name containing item list (default: "list")
- **`--fileName <prop>`**: Property to use as filename (default: "title")
- **`--fallbackFileName <prop>`**: Fallback property for filename if primary is empty (default: "name")
- **`--content <prop>`**: Property name for file content (default: "html")
- **`--fileExtension <ext>`**: Extension for generated files (default: "html")
- **`-d, --download`**: Enable downloading of media resources
- **`--assetsDir <dir>`**: Directory for saving media assets (default: "assets")
- **`--assetsPrefix <prefix>`**: Prefix for asset filenames (default: "")
- **`--uniqueAssetName`**: Add unique index prefix to asset filenames (default: true)
- **`--replaceUrls`**: Replace resource URLs in file content with local paths (default: true)
- **`--baseUrl <url>`**: Base URL for processing relative paths
- **`-p, --prefix <value>`**: Add prefix to all generated filenames
- **`-e, --exec <command>`**: Execute command for each created file, supports special placeholders
- **`--execParallel`**: Execute commands in parallel (default: sequential)
- **`--execTimeout <ms>`**: Command execution timeout (default: 30000ms)
- **`-v, --verbose`**: Show detailed processing information
- **`-h, --help`**: Show help information

### Command Placeholders
- **`{file}`**: Filename without extension
- **`{ext}`**: File extension
- **`{filepath}`**: Complete file path
- **`{dir}`**: Directory containing the file

### Example Workflows

#### Blog Post Generation
```bash
# Generate Markdown files from blog posts JSON
node json-to-files.js blog_data.json -o ./blog_posts --fileExtension md --listProp posts --content body
```

#### Product Catalog with Images
```bash
# Generate product pages with downloaded images
node json-to-files.js products.json -d --assetsDir product_images -o ./catalog
```

#### Content Migration with Transformation
```bash
# Generate HTML files and convert them to another format
node json-to-files.js content.json -e "pandoc -f html -t docx -o {dir}/{file}.docx {filepath}" --execParallel
```

### Sample JSON Structure
```json
{
  "list": [
    {
      "title": "First Article",
      "name": "article-1",
      "html": "<p>Content with <img src='images/photo.jpg'></p>"
    },
    {
      "title": "Second Article",
      "name": "article-2",
      "html": "<p>More content with <video src='videos/clip.mp4'></video></p>"
    }
  ]
}
```

## Swagger API Path Filter

`swagger-filter.js` is a versatile Node.js script designed to filter Swagger/OpenAPI JSON documents by retaining only API paths that match specified prefixes. It supports both command-line and interactive modes for different usage scenarios.

### Features
- **Path Prefix Filtering**: Retain only API paths that start with specified prefixes
- **Multiple Prefix Support**: Filter by multiple path prefixes simultaneously
- **Preserve Document Structure**: Maintain original Swagger document structure and metadata
- **Dual Operation Modes**: Command-line mode for automation and interactive mode for manual use
- **Statistics Reporting**: Display detailed information about filtered paths
- **Error Handling**: Comprehensive error handling with informative messages

### Requirements
- Node.js 10.x or higher

### Usage

#### Command-Line Mode (Recommended for Automation)

Filter paths with a single prefix:
```bash
node swagger-filter.js --input api-docs.json --output filtered.json --include /open/api
```

Filter paths with multiple prefixes:
```bash
node swagger-filter.js --input api-docs.json --output filtered.json --include /open/api,/public/v1
```

#### Interactive Mode (For Manual Operations)

Run the script without parameters to enter interactive mode:
```bash
node swagger-filter.js
```

The script will guide you through entering:
- Input file path (default: `api-docs.json`)
- Output file path (default: `filtered-swagger.json`)
- Path prefixes to include (default: `/open`)

### Command-Line Options
- **`--input <filepath>`**: Required. Path to the input Swagger JSON file
- **`--output <filepath>`**: Optional. Path for the filtered output file (default: `filtered-swagger.json`)
- **`--include <prefixes>`**: Required. Comma-separated list of path prefixes to retain

### Example Workflows

#### API Documentation Filtering
```bash
# Filter to keep only public API endpoints
node swagger-filter.js --input full-api.json --output public-api.json --include /public,/open

# Filter to keep only admin endpoints
node swagger-filter.js --input full-api.json --output admin-api.json --include /admin,/internal
```

#### Microservice API Extraction
```bash
# Extract user service endpoints
node swagger-filter.js --input monolith-api.json --output user-service.json --include /api/users,/api/auth

# Extract payment service endpoints
node swagger-filter.js --input monolith-api.json --output payment-service.json --include /api/payments,/api/billing
```

### Sample Output
```
正在从文件 "api-docs.json" 中保留指定前缀的路径...
--- 任务完成 ---
成功将过滤后的内容保存到文件: "filtered-swagger.json"
原始路径数量: 150, 保留路径数量: 45, 移除路径数量: 105
```

### Input/Output Format
The script processes standard Swagger/OpenAPI JSON documents and preserves the complete document structure while filtering only the `paths` object. All other components (info, servers, components, etc.) remain unchanged.
