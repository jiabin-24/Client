## 1. Create a Storage Account (Container) in Azure

> Note: The Storage must be reachable by the GitHub platform (it can be publicly accessible or whitelisted for GitHub).

Create a Container to store GitHub Enterprise logs (for example: `github-audit-log`), then click the container's "..." and generate a SAS access link.

![azure-container](./images/azure-container.png)

Set the SAS link expiration to one year (or configure as needed) and keep other settings at their defaults. Click "Generate SAS token and URL" and copy the generated Blob SAS URL (you will configure this in GitHub later).

![azure-container-sas](./images/azure-container-sas.png)

## 2. Configure GitHub Audit Log Stream

Go to GitHub Enterprise Settings -> Audit log -> Log streaming, click "Configure stream -> Azure Blob Storage" to add a new configuration.

![github-audit](./images/enterprise-audit-log.png)

Fill in the Azure Storage information you created earlier and save.

![githu-audit-config](./images/enterprise-audit-log-config.png)

At this point, GitHub platform logs will be pushed in near real-time (delay: minutes) to the specified Azure Storage (Container). Next, configure ELK to pull these logs in real time.

![github-log-record](./images/enterprise-audit-log-record.png)

## 2. Configure ELK to periodically pull Azure Container (GitHub Enterprise) logs

In ELK's "Integrations", install the "Custom Azure Blob Storage Input" integration.

![elk-integration](./images/elk-integration.png)

Then configure it — pay attention to the following values:

- **Account Name**: enter the Azure Storage account name
- **Service Account Key**: enter the Azure Storage account key
- **Dataset name**: enter `github.audit` (you can change this if desired)
- **Containers**: YAML format — set `name` to the container you created earlier (`github-audit-log`)
- **File Selectors**: YAML format — set `regex` to the log files you want to collect (here set to `".*"`)

![elk-inte-conf](./images/elk-integration-config.png)

Then click Save.

Install an Agent (the Agent performs the log collection and must be able to reach the Azure Container). Run the provided install script on a prepared physical or virtual machine. After installation you should see the Agent status in the ELK UI.

![elk-add-agent](./images/elk-add-agent.png)
![elk-agent](./images/elk-agent.png)

## 3. View GitHub Audit Logs in ELK

Go to Discover, open the Data view dropdown in the top-left, and click "Create a data view" to create a view for the GitHub audit logs.

![elk-add-dataview](./images/elk-add-data-view.png)

Configure the data view as shown below (note: the previous steps must be completed so the index is available to configure).

![elk-config-dataview](./images/elk-config-data-view.png)

After saving, you can view the GitHub Audit Log in Discover.

![elk-github-log](./images/elk-logs.png)

