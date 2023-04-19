#Version 1

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#Hide console
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

#Limits the amount of counter to display
$maxCounterToDisplay = 200

$availableCounterPaths = (get-counter -listset *).PathsWithInstances

$mainForm = New-Object system.Windows.Forms.Form
$mainForm.ClientSize = '800,600'
$mainForm.MinimumSize = '200,200'
$mainForm.text = "Performance Counter Viewer"
$mainForm.TopMost = $false
$mainForm.ShowIcon = $false
$mainForm.AutoScroll = $true

$searchTextBox = New-Object System.Windows.Forms.TextBox
$searchTextBox.Location = New-Object System.Drawing.Point(0, 0)
$searchTextBox.Name = 'searchTextBox'
$searchTextBox.Size = New-Object System.Drawing.Size(800, 23)
$searchTextBox.TabIndex = 2
$searchTextBox.Anchor = 'top,right,left'
$searchTextBox.Text = 'CPU'
$mainForm.Controls.Add($searchTextBox)

$filterBtn = New-Object System.Windows.Forms.Button
$filterBtn.Location = New-Object System.Drawing.Point(0, 23)
$filterBtn.Name = 'filterBtn'
$filterBtn.Size = New-Object System.Drawing.Size(70, 23)
$filterBtn.TabIndex = 3
$filterBtn.Text = "Filter"
$filterBtn.UseVisualStyleBackColor = $true
$filterBtn.Anchor = 'top,left'
$mainForm.Controls.Add($filterBtn)

$yOffset = 46

$genericButtons = New-Object System.Collections.Generic.List[System.Windows.Forms.Button]
$genericTextBoxes = New-Object System.Collections.Generic.List[System.Windows.Forms.TextBox]


function getCounterValue($counterPath) {
    $counterValueResult = (Get-Counter -Counter $counterPath -ErrorAction 'silentlycontinue').CounterSamples.CookedValue

    if ($counterValueResult -eq $null) {
        return "N/A"
    }

    return $counterValueResult
}


function createCounterGrid($counterPathlist) {
    $rowHeight = 23

    for ($i = 0; $i -lt $counterPathlist.Count; $i++) {
        $currentCounterPath = $counterPathlist[$i]
        $yLocation = $yOffset + ($i * $rowHeight)

        $counterPathBox = New-Object System.Windows.Forms.TextBox
        $counterPathBox.ReadOnly = $true
        $counterPathBox.Location = New-Object System.Drawing.Point(0, $yLocation)
        $counterPathBox.Name = "counterPathBox_$i"
        $counterPathBox.Size = New-Object System.Drawing.Size(720, $rowHeight)
        $counterPathBox.TabIndex = 1
        $counterPathBox.Text = $currentCounterPath
        $counterPathBox.TextAlign = 'left'
        $counterPathBox.Anchor = 'top,right,left'
        $mainForm.Controls.Add($counterPathBox)

        $genericTextBoxes.Add($counterPathBox)

        $counterValueBtn = New-Object System.Windows.Forms.Button
        $counterValueBtn.Location = New-Object System.Drawing.Point(720, ($yLocation - 1))
        $counterValueBtn.Name = "counterValueBtn_$i"
        $counterValueBtn.Tag = $currentCounterPath
        $counterValueBtn.Size = New-Object System.Drawing.Size(80, ($rowHeight - 1))
        $counterValueBtn.TabIndex = 1
        $counterValueBtn.Anchor = 'top,right'
        $mainForm.Controls.Add($counterValueBtn)

        $genericButtons.Add($counterValueBtn)

        $counterValueBtn.Add_Click( {
                $this.Text = "Loading...."
                $this.Text = getCounterValue($this.Tag) 
            })
    }
}

function createCounterGridBasedOnFilter() {
    clearFormsControls
    $filterBtn.Text = 'Loading....'
    $filterBtn.Enabled = $false
    $searchText = [regex]::Escape($searchTextBox.Text)
    $reducedCounterPaths = $availableCounterPaths | Where-Object { $_ -match $searchText }

    if ($reducedCounterPaths.Count -ge $maxCounterToDisplay) {
        $reducedCounterPaths = $reducedCounterPaths | Select-Object -First $maxCounterToDisplay
        [System.Windows.Forms.MessageBox]::Show("Too many counter found! First $maxCounterToDisplay counter are displayed", "Warning", 0, 'Warn')
    }

    createCounterGrid($reducedCounterPaths)
    $filterBtn.Text = 'Filter'
    $filterBtn.Enabled = $true
}

function clearFormsControls() {
    foreach ($genericButton in $genericButtons) {
        $mainForm.Controls.Remove($genericButton)
    }

    foreach ($genericTextBox in $genericTextBoxes) {
        $mainForm.Controls.Remove($genericTextBox)
    }

    $genericButtons.Clear()
    $genericTextBoxes.Clear()
}


$filterBtn.Add_Click( { createCounterGridBasedOnFilter })
$searchTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            createCounterGridBasedOnFilter
        }
    })
 

$mainForm.ShowDialog()