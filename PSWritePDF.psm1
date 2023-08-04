Expand the file name to include leading zeros depending on the number of files created
For example, if 12 files are created, we get 00, 01, ...., 09, 10, 11

A new optional parameter, StartIndex, is added to begin the file numbering at a specific value instead oh the default value 0
Hence, for 12 files, we get  01, 02, ...., 09, 10, 11, 12






class CustomSplitter : iText.Kernel.Utils.PdfSplitter {
    [int] $_order
    [string] $_destinationFolder
    [string] $_outputName
	[string] $_Mask
	
    CustomSplitter([iText.Kernel.Pdf.PdfDocument] $pdfDocument, [string] $destinationFolder, [string] $OutputName, [int] $StartIndex) : base($pdfDocument) {
        $this._destinationFolder = $destinationFolder
        $this._order = $StartIndex
        $this._outputName = $OutputName
		$this._Mask = ("0" * ($pdfDocument.GetNumberOfPages()).ToString().Length)		
    }

    [iText.Kernel.Pdf.PdfWriter] GetNextPdfWriter([iText.Kernel.Utils.PageRange] $documentPageRange) {
        $Name = $this._outputName+$this._order.ToString($this._Mask)+".pdf"
		$this._order++
        $Path = [IO.Path]::Combine($this._destinationFolder, $Name)
        return [iText.Kernel.Pdf.PdfWriter]::new($Path)
    }
}
#
#
#
function Split-PDF {
    <#
    .SYNOPSIS
    Split PDF file into multiple files.

    .DESCRIPTION
    Split PDF file into multiple files. The output files will be named based on OutputName variable with appended numbers

    .PARAMETER FilePath
    The path to the PDF file to split.

    .PARAMETER OutputFolder
    The folder to output the split files to.

    .PARAMETER OutputName
    The name of the output files. Default is OutputDocument

    .PARAMETER SplitCount
    The number of pages to split the PDF file into. Default is 1

    .PARAMETER StartIndex
    The starting value for the PDF files numbering. Default is 0
	
    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    Split-PDF -FilePath "$PSScriptRoot\SampleToSplit.pdf" -OutputFolder "$PSScriptRoot\Output"

    .EXAMPLE
    Split-PDF -FilePath "\\ad1\c$\SampleToSplit.pdf" -OutputFolder "\\ad1\c$\Output"

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [Parameter(Mandatory)][string] $OutputFolder,
        [string] $OutputName = 'OutputDocument',
        [int] $SplitCount = 1,
		[int] $StartIndex = 0,		
        [switch] $IgnoreProtection
    )
    if ($SplitCount -eq 0) {
        Write-Warning "Split-PDF - SplitCount is 0. Terminating."
        return
    }

    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $ResolvedPath = Convert-Path -LiteralPath $FilePath
        if ($OutputFolder -and (Test-Path -LiteralPath $OutputFolder)) {
            try {
                $PDFFile = [iText.Kernel.Pdf.PdfReader]::new($ResolvedPath)
                if ($IgnoreProtection) {
                    $null = $PDFFile.SetUnethicalReading($true)
                }
                $Document = [iText.Kernel.Pdf.PdfDocument]::new($PDFFile)
                $Splitter = [CustomSplitter]::new($Document, $OutputFolder, $OutputName, $StartIndex)
                $List = $Splitter.SplitByPageCount($SplitCount)
                foreach ($_ in $List) {
                    $_.Close()
                }
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Split-PDF - Error has occured: $ErrorMessage"
            }
            try {
                $PDFFile.Close()
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Split-PDF - Closing document $FilePath failed with error: $ErrorMessage"
            }
        } else {
            Write-Warning "Split-PDF - Destination folder $OutputFolder doesn't exists. Terminating."
        }
    } else {
        Write-Warning "Split-PDF - Path $FilePath doesn't exists. Terminating."
    }
}
