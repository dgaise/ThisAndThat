const fs = require('fs');
const { Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel, LevelFormat, WidthType, BorderStyle, Table, TableRow, TableCell } = require('docx');
 
const doc = new Document({
  styles: {
    default: { 
      document: { 
        run: { font: "Arial", size: 22 }
      } 
    },
    paragraphStyles: [
      {
        id: "Heading1",
        name: "Heading 1",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: "000000" },
        paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 0 }
      },
    ]
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          {
            level: 0,
            format: LevelFormat.BULLET,
            text: "•",
            alignment: AlignmentType.LEFT,
            style: {
              paragraph: {
                indent: { left: 720, hanging: 360 }
              }
            }
          }
        ]
      }
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 120 },
        children: [
          new TextRun({ text: "DAVID GAISER", bold: true, size: 32, font: "Arial" })
        ]
      }),
      
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 240 },
        children: [
          new TextRun({ text: "Senior Data Engineer | Database Architecture | Distributed Systems | Python Development", size: 22 })
        ]
      }),
      
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 360 },
        children: [
          new TextRun({ text: "+1-415-994-9443 | dgaise@gmail.com | linkedin.com/in/davidgaiser", size: 20 })
        ]
      }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("PROFESSIONAL SUMMARY")]
      }),
      
      new Paragraph({
        spacing: { after: 240 },
        children: [
          new TextRun({
            text: "Senior Data Engineer with 15+ years of software engineering experience focused on databases, data pipelines, and distributed systems. Expert in building and optimizing database architectures for large-scale enterprise systems. Strong proficiency in SQL and NoSQL databases (Oracle, PostgreSQL, MySQL, MongoDB, Redis, DynamoDB), with deep understanding of data modeling, indexing, and query optimization. Experienced developing backend services in Python, Java, and other languages that efficiently interact with external data systems. Proven track record improving performance, scalability, and reliability of data storage and retrieval systems in Linux environments. Strong analytical and problem-solving skills with experience in decentralized systems and extensive data frameworks.",
            size: 22
          })
        ]
      }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("CORE COMPETENCIES")]
      }),
 
      new Table({
        width: { size: 100, type: WidthType.PERCENTAGE },
        columnWidths: [3120, 3120, 3120],
        borders: {
          top: { style: BorderStyle.NONE },
          bottom: { style: BorderStyle.NONE },
          left: { style: BorderStyle.NONE },
          right: { style: BorderStyle.NONE },
          insideHorizontal: { style: BorderStyle.NONE },
          insideVertical: { style: BorderStyle.NONE }
        },
        rows: [
          new TableRow({
            children: [
              new TableCell({
                width: { size: 3120, type: WidthType.DXA },
                borders: {
                  top: { style: BorderStyle.NONE },
                  bottom: { style: BorderStyle.NONE },
                  left: { style: BorderStyle.NONE },
                  right: { style: BorderStyle.NONE }
                },
                children: [
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Database Architecture")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("SQL & NoSQL Databases")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Data Pipeline Optimization")] })
                ]
              }),
              new TableCell({
                width: { size: 3120, type: WidthType.DXA },
                borders: {
                  top: { style: BorderStyle.NONE },
                  bottom: { style: BorderStyle.NONE },
                  left: { style: BorderStyle.NONE },
                  right: { style: BorderStyle.NONE }
                },
                children: [
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Backend Services Development")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Distributed Systems")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Python & Java Development")] })
                ]
              }),
              new TableCell({
                width: { size: 3120, type: WidthType.DXA },
                borders: {
                  top: { style: BorderStyle.NONE },
                  bottom: { style: BorderStyle.NONE },
                  left: { style: BorderStyle.NONE },
                  right: { style: BorderStyle.NONE }
                },
                children: [
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Performance & Scalability")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("System Observability")] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Linux Environments")] })
                ]
              })
            ]
          })
        ]
      }),
 
      new Paragraph({ spacing: { after: 240 }, children: [] }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("PROFESSIONAL EXPERIENCE")]
      }),
 
      new Paragraph({
        spacing: { after: 80 },
        children: [
          new TextRun({ text: "Software Developer, Business Intelligence Team", bold: true, size: 24 }),
          new TextRun({ text: " | AssetMark, Concord, CA | Feb 2025-Dec 2025", size: 24 })
        ]
      }),
 
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Built and optimized database architectures and data pipelines for business intelligence systems, improving query performance and data processing efficiency")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Developed backend services in Python and PowerShell that efficiently interact with external data systems including SQL Server and Azure cloud services")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Implemented query optimization strategies using T-SQL stored procedures and functions, significantly improving performance of data retrieval systems")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Contributed to system observability and monitoring by configuring alerts and automation workflows to proactively detect data pipeline issues")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        spacing: { after: 240 },
        children: [new TextRun("Troubleshot complex issues in distributed data environments, diagnosing root causes across multiple integrated systems")]
      }),
 
      new Paragraph({
        spacing: { after: 80 },
        children: [
          new TextRun({ text: "Software Development Specialist", bold: true, size: 24 }),
          new TextRun({ text: " | Vindicia, San Mateo, CA | 2022-Oct 2024", size: 24 })
        ]
      }),
 
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Designed, implemented, and optimized database architectures across PostgreSQL, MySQL, and DynamoDB (NoSQL) for distributed SaaS platform handling millions of transactions")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Developed backend services in Python (Flask), Java, and Perl that efficiently interacted with relational and NoSQL databases in production environments")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Applied deep understanding of data modeling, indexing strategies, and query optimization to improve database performance and reduce query execution times")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Improved performance, scalability, and reliability of data storage systems by implementing connection pooling, caching strategies, and database partitioning")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Worked extensively in Linux environments troubleshooting complex issues in distributed data systems across 50+ microservices architecture")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Built monitoring and automation solutions using Grafana, Kibana, and AWS CloudWatch to enhance system observability and operational efficiency")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Worked with decentralized systems and extensive data frameworks including AWS services (S3, Athena, Lambda) and containerized environments (Docker, Kubernetes)")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        spacing: { after: 240 },
        children: [new TextRun("Gained familiarity with networking concepts through troubleshooting distributed system communications and API integrations")]
      }),
 
      new Paragraph({
        spacing: { after: 80 },
        children: [
          new TextRun({ text: "Application Support Team Lead", bold: true, size: 24 }),
          new TextRun({ text: " | Amdocs, San Francisco, CA | 2014-2022", size: 24 })
        ]
      }),
 
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Built and optimized Oracle database architectures for enterprise-level systems, developing complex PL/SQL stored procedures, packages, and triggers")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Led database performance optimization project where I denormalized heavily normalized schema, reducing query execution time by 65% through strategic data modeling")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Developed backend services in Java and Perl working with Oracle SQL, MySQL, and PostgreSQL database management systems")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Applied advanced understanding of indexing, query optimization, and database tuning to improve scalability of systems serving 200,000+ users")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Implemented automation workflows and monitoring systems in Linux environments to ensure reliability of data pipelines and database operations")]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        spacing: { after: 360 },
        children: [new TextRun("Troubleshot complex issues in distributed enterprise systems, using strong analytical and problem-solving skills to diagnose and resolve data-related problems")]
      }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("TECHNICAL SKILLS")]
      }),
 
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "SQL Databases (15+ years): ", bold: true }),
          new TextRun("Oracle SQL, PostgreSQL, MySQL, MS SQL Server, advanced SQL, PL/SQL, T-SQL, stored procedures, query optimization, indexing strategies, database tuning")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "NoSQL Databases (5+ years): ", bold: true }),
          new TextRun("MongoDB, DynamoDB, Redis, key-value stores, document databases, NoSQL data modeling")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Programming Languages (10+ years): ", bold: true }),
          new TextRun("Python (Flask, Django), Java, Perl, Bash scripting, PowerShell, backend service development")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Database Engineering: ", bold: true }),
          new TextRun("Data modeling, indexing, query optimization, database architecture design, performance tuning, data pipeline development, ETL/ELT processes")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Distributed Systems (10+ years): ", bold: true }),
          new TextRun("Microservices architecture, distributed databases, decentralized systems, extensive data frameworks, data consistency patterns")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Linux Environments (15+ years): ", bold: true }),
          new TextRun("Linux system administration, Unix environments, shell scripting, system troubleshooting, performance analysis")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Cloud & Containers: ", bold: true }),
          new TextRun("AWS (EC2, EKS, S3, Lambda, RDS, Athena, DynamoDB), Azure, Docker, Kubernetes, cloud-native data platforms, containerized environments")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        children: [
          new TextRun({ text: "Monitoring & Observability: ", bold: true }),
          new TextRun("Grafana, Prometheus, Kibana/ELK, CloudWatch, Splunk, system monitoring, alerting, automation, performance tracking")
        ]
      }),
      new Paragraph({
        numbering: { reference: "bullets", level: 0 },
        spacing: { after: 360 },
        children: [
          new TextRun({ text: "Additional Technologies: ", bold: true }),
          new TextRun("REST APIs, networking concepts, data streaming (familiar with Kafka), CI/CD pipelines, Git, Jira")
        ]
      }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("EDUCATION & CERTIFICATIONS")]
      }),
 
      new Paragraph({
        spacing: { after: 80 },
        children: [
          new TextRun({ text: "Bachelor of Science in Industrial Engineering & Management", bold: true }),
          new TextRun(" | Tel Aviv University, Israel")
        ]
      }),
 
      new Paragraph({
        children: [
          new TextRun({ text: "Technical Training: ", bold: true }),
          new TextRun("Oracle Advanced SQL & Database Administration | Django for Everybody (Python) | MongoDB Fundamentals | Data Visualization")
        ]
      }),
 
      new Paragraph({ spacing: { after: 240 }, children: [] }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("KEY PROJECT")]
      }),
 
      new Paragraph({
        spacing: { after: 80 },
        children: [
          new TextRun({ text: "Database Architecture Optimization for High-Performance Reporting", bold: true })
        ]
      }),
 
      new Paragraph({
        spacing: { after: 360 },
        children: [
          new TextRun("Led database optimization project where I redesigned normalized reporting database architecture to dramatically improve performance. Analyzed query patterns and data access behavior across 15+ tables, identified bottleneck joins, and strategically denormalized schema for read-optimized access. Implemented comprehensive indexing strategy and query optimization techniques. Reduced query execution time from 120+ seconds to under 5 seconds (65% improvement), eliminated timeout issues, and enabled system to handle 3x concurrent load. Demonstrated strong understanding of data modeling, indexing, performance tuning, and scalability optimization.")
        ]
      }),
 
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("LANGUAGES")]
      }),
 
      new Paragraph({
        children: [new TextRun("English (fluent), Russian (fluent), Hebrew (native)")]
      })
    ]
  }]
});
 
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("js/David_Gaiser_NVIDIA_Israel_Resume.docx", buffer);
  console.log("Resume created successfully!");
});
