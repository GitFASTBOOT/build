/*
 * Copyright (C) 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package android.os.flagging;

import android.aconfig.storage.AconfigStorageException;
import android.aconfig.storage.FlagValueList;
import android.aconfig.storage.PackageTable;
import android.aconfig.storage.StorageFileProvider;
import android.compat.annotation.UnsupportedAppUsage;
import android.os.StrictMode;

/**
 * An {@code aconfig} package containing the enabled state of its flags.
 *
 * <p><strong>Note: this is intended only to be used by generated code. To determine if a given flag
 * is enabled in app code, the generated android flags should be used.</strong>
 *
 * <p>This class is not part of the public API and should be used by Acnofig Flag internally </b> It
 * is intended for internal use only and will be changed or removed without notice.
 *
 * <p>This class is used to read the flag from Aconfig Package.Each instance of this class will
 * cache information related to one package. To read flags from a different package, a new instance
 * of this class should be {@link #load loaded}.
 *
 * @hide
 */
public class PlatformAconfigPackageInternal {

    private final FlagValueList mFlagValueList;
    private final long mFingerprint;
    private final int mPackageBooleanStartOffset;
    private final AconfigStorageReadException mException;

    private PlatformAconfigPackageInternal(
            FlagValueList flagValueList,
            long fingerprint,
            int packageBooleanStartOffset,
            AconfigStorageReadException exception) {
        this.mFlagValueList = flagValueList;
        this.mFingerprint = fingerprint;
        this.mPackageBooleanStartOffset = packageBooleanStartOffset;
        this.mException = exception;
    }

    /**
     * Loads an Aconfig Package from Aconfig Storage.
     *
     * <p>This method loads the specified Aconfig Package from the given container.
     *
     * <p>AconfigStorageReadException will be stored if there is an error reading from Aconfig
     * Storage. The specific error code can be got using {@link #getException()}.
     *
     * @param container The name of the container.
     * @param packageName The name of the Aconfig package to load.
     * @return An instance of {@link PlatformAconfigPackageInternal}
     * @hide
     */
    @UnsupportedAppUsage
    public static PlatformAconfigPackageInternal load(String container, String packageName) {
        return load(container, packageName, StorageFileProvider.getDefaultProvider());
    }

    /** @hide */
    public static PlatformAconfigPackageInternal load(
            String container, String packageName, StorageFileProvider fileProvider) {
        StrictMode.ThreadPolicy oldPolicy = StrictMode.allowThreadDiskReads();
        try {
            PackageTable.Node pNode = fileProvider.getPackageTable(container).get(packageName);

            if (pNode == null) {
                return createExceptionInstance(
                        AconfigStorageReadException.ERROR_PACKAGE_NOT_FOUND,
                        "package "
                                + packageName
                                + " in container "
                                + container
                                + " cannot be found on the device");
            }

            return new PlatformAconfigPackageInternal(
                    fileProvider.getFlagValueList(container),
                    pNode.getPackageFingerprint(),
                    pNode.getBooleanStartIndex(),
                    null);
        } catch (AconfigStorageException e) {
            return createExceptionInstance(e.getErrorCode(), e.getMessage());
        } finally {
            StrictMode.setThreadPolicy(oldPolicy);
        }
    }

    /**
     * Retrieves the value of a boolean flag using its index.
     *
     * <p>This method is intended for internal use only and may be changed or removed without
     * notice.
     *
     * <p>This method retrieves the value of a flag within the loaded Aconfig package using its
     * index. The index is generated at build time and may vary between builds.
     *
     * <p>To ensure you are using the correct index, verify that the package's fingerprint matches
     * the expected fingerprint before calling this method. If the fingerprints do not match, use
     * {@link #getBooleanFlagValue(String, boolean)} instead.
     *
     * @param index The index of the flag within the package.
     * @return The boolean value of the flag.
     * @hide
     */
    @UnsupportedAppUsage
    public boolean getBooleanFlagValue(int index) {
        return mFlagValueList.getBoolean(index + mPackageBooleanStartOffset);
    }

    /**
     * Returns any exception that occurred during the loading of the Aconfig package.
     *
     * <p>This method is intended for internal use only and may be changed or removed without
     * notice.
     *
     * @return The exception that occurred, or {@code null} if no exception occurred.
     * @hide
     */
    @UnsupportedAppUsage
    public AconfigStorageReadException getException() {
        return mException;
    }

    @UnsupportedAppUsage
    public long getPackageFingerprint() {
        return mFingerprint;
    }

    /**
     * Creates a new {@link PlatformAconfigPackageInternal} instance with an {@link
     * AconfigStorageReadException}.
     *
     * @param errorCode The error code for the exception.
     * @param message The error message for the exception.
     * @return A new {@link PlatformAconfigPackageInternal} instance with the specified exception.
     */
    private static PlatformAconfigPackageInternal createExceptionInstance(
            int errorCode, String message) {
        return new PlatformAconfigPackageInternal(
                null, 0, 0, new AconfigStorageReadException(errorCode, message));
    }
}
